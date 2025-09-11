# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  describe 'clear command' do
    include OpenAIMockHelper
    include McpMockHelper
    include RobotFactory

    subject(:call_robot) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

    let(:robot) { create_robot(env:) }
    let(:brain) { robot.brain }
    let(:database) { Ruboty::AiAgent::Database.new(brain) }
    let(:env) do
      {
        'OPENAI_API_KEY' => 'test_api_key',
        'OPENAI_MODEL' => 'gpt-5-nano',
        'DEBUG' => nil,
        'OPENAI_ORG_ID' => nil
      }
    end

    let(:from) { 'test_user' }
    let(:to) { 'ruboty' }
    let(:body) { '/clear' }

    def said_messages
      robot.adapter.messages
    end

    describe 'with /clear command' do
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
          call_robot
          expect(chat_thread.messages.all_values).to be_empty
        end

        it 'replies with clear confirmation message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Cleared the chat history.'))
        end

        it 'does not call OpenAI API' do
          # No API stub setup - test will fail if API is called
          expect { call_robot }.not_to raise_error
        end
      end

      context 'when chat thread is already empty' do
        it 'still replies with clear confirmation message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Cleared the chat history.'))
        end

        it 'keeps the chat thread empty' do
          expect(chat_thread.messages.all_values).to be_empty
          call_robot
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
              call_robot
              expect(said_messages).to include(a_hash_including(body: 'Cleared the chat history.'))
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
          call_robot
          # Should have added new messages, not cleared
          expect(chat_thread.messages.all_values.length).to be > initial_count
        end

        it 'processes as normal chat message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Did you mean to clear the chat history? Use /clear command.'))
        end
      end

      context 'when after clearing' do
        subject(:receive_second_message) do
          stub_openai_chat_completion_with_content(
            messages: [
              { role: 'user', content: 'Hello again!' }
            ],
            response_content: 'Hello! Starting fresh. How can I help you?'
          )

          robot.receive(body: "#{robot.name} Hello again!", from:, to:)
        end

        before do
          # Add initial messages to chat thread before clearing
          database.chat_thread(from).messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :user,
              content: 'Old conversation'
            )
          )
        end

        it 'can start a new conversation after clearing' do # rubocop:disable RSpec/ExampleLength
          expect(database.chat_thread(from).messages.all_values).not_to be_empty

          # Clear the history
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Cleared the chat history.'))
          expect(database.chat_thread(from).messages.all_values).to be_empty

          # Start new conversation
          receive_second_message
          expect(said_messages).to include(a_hash_including(body: 'Hello! Starting fresh. How can I help you?'))

          # Should have new messages
          messages = database.chat_thread(from).messages.all_values
          expect(messages.length).to eq(2)
          expect(messages[0]).to have_attributes(role: :user, content: 'Hello again!')
          expect(messages[1]).to have_attributes(role: :assistant, content: 'Hello! Starting fresh. How can I help you?')
        end
      end
    end
  end
end
