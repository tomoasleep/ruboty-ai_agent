# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe 'Clear command in Ruboty::AiAgent::Actions::Chat' do
  include OpenAIMockHelper
  include McpMockHelper

  subject(:action) { Ruboty::AiAgent::Actions::Chat.new(message) }

  let(:robot) { Ruboty::Robot.new }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { '/clear' }

  let(:original_message) do
    Ruboty::Message.new(
      body: body,
      from: from,
      to: to,
      robot: robot
    )
  end

  let(:message) do
    message = original_message
    allow(message).to receive(:reply)
    allow(message).to receive(:[]).with(:body).and_return(body)
    message
  end

  before do
    # Stub ENV variables
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_api_key')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-5-nano').and_return('gpt-5')
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DEBUG').and_return(nil)
    allow(ENV).to receive(:[]).with('OPENAI_ORG_ID').and_return(nil)

    # Allow action to use real database
    allow(action).to receive(:database).and_return(database)
    allow(action).to receive(:robot).and_return(robot)
  end

  describe '#call with /clear command' do
    subject(:call_action) { action.call }

    let(:chat_thread) { database.chat_thread(from) }

    context 'when there is existing chat history' do
      before do
        # Add some messages to the chat thread
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'Hello, AI!'
          )
        )
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: 'Hello! How can I help you today?'
          )
        )
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'What is the weather?'
          )
        )
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: 'I cannot check the weather in real-time.'
          )
        )
      end

      it 'clears all messages from the chat thread' do
        expect(chat_thread.messages.all_values).not_to be_empty
        call_action
        expect(chat_thread.messages.all_values).to be_empty
      end

      it 'replies with clear confirmation message' do
        expect(message).to receive(:reply).with('Cleared the chat history.')
        call_action
      end

      it 'does not call OpenAI API' do
        # No API stub setup - test will fail if API is called
        expect { call_action }.not_to raise_error
      end
    end

    context 'when chat thread is already empty' do
      it 'still replies with clear confirmation message' do
        expect(message).to receive(:reply).with('Cleared the chat history.')
        call_action
      end

      it 'keeps the chat thread empty' do
        expect(chat_thread.messages.all_values).to be_empty
        call_action
        expect(chat_thread.messages.all_values).to be_empty
      end
    end

    context 'with variations of /clear command' do
      [
        '/clear',
        '  /clear',
        '/clear  ',
        '  /clear  ',
        '/clear with extra text'
      ].each do |command_text|
        context "when body is '#{command_text}'" do
          let(:body) { command_text }

          it 'matches and executes the clear command' do
            expect(message).to receive(:reply).with('Cleared the chat history.')
            call_action
          end
        end
      end
    end

    context 'when command does not match /clear' do
      let(:body) { 'clear' } # without slash

      before do
        # Add some existing messages
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'Previous message'
          )
        )

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: 'Previous message' },
            { role: 'user', content: body }
          ],
          response_content: 'Did you mean to clear the chat history? Use /clear command.'
        )
      end

      it 'does not clear the chat thread' do
        initial_count = chat_thread.messages.all_values.length
        call_action
        # Should have added new messages, not cleared
        expect(chat_thread.messages.all_values.length).to be > initial_count
      end

      it 'processes as normal chat message' do
        expect(message).to receive(:reply).with('Did you mean to clear the chat history? Use /clear command.')
        call_action
      end
    end

    context 'after clearing, new conversation can start' do
      it 'can start a new conversation after clearing' do
        # Add initial messages to chat thread before clearing
        database.chat_thread(from).messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'Old conversation'
          )
        )
        expect(database.chat_thread(from).messages.all_values).not_to be_empty

        # Clear the history
        expect(message).to receive(:reply).with('Cleared the chat history.')
        call_action
        expect(database.chat_thread(from).messages.all_values).to be_empty

        # Create new message and action for second call
        second_message = Ruboty::Message.new(
          body: 'Hello again!',
          from: from,
          to: to,
          robot: robot
        )
        allow(second_message).to receive(:reply)
        allow(second_message).to receive(:[]).with(:body).and_return('Hello again!')

        second_action = Ruboty::AiAgent::Actions::Chat.new(second_message)
        allow(second_action).to receive(:database).and_return(database)
        allow(second_action).to receive(:robot).and_return(robot)

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: 'Hello again!' }
          ],
          response_content: 'Hello! Starting fresh. How can I help you?'
        )

        # Start new conversation
        expect(second_message).to receive(:reply).with('Hello! Starting fresh. How can I help you?')
        second_action.call

        # Should have new messages
        messages = database.chat_thread(from).messages.all_values
        expect(messages.length).to eq(2)
        expect(messages[0]).to have_attributes(role: :user, content: 'Hello again!')
        expect(messages[1]).to have_attributes(role: :assistant, content: 'Hello! Starting fresh. How can I help you?')
      end
    end
  end
end
