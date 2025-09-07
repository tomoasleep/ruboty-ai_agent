# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe 'Compact command in Ruboty::AiAgent::Actions::Chat' do
  include OpenAIMockHelper
  include McpMockHelper

  subject(:action) { Ruboty::AiAgent::Actions::Chat.new(message) }

  let(:robot) { Ruboty::Robot.new }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { '/compact' }

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
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_api_key')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-5-nano').and_return('gpt-5')
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DEBUG').and_return(nil)
    allow(ENV).to receive(:[]).with('OPENAI_ORG_ID').and_return(nil)

    allow(action).to receive(:database).and_return(database)
    allow(action).to receive(:robot).and_return(robot)
  end

  describe '#call with /compact command' do
    subject(:call_action) { action.call }

    let(:chat_thread) { database.chat_thread(from) }

    context 'when there is existing chat history' do
      before do
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

        stub_openai_chat_completion_with_content(
          messages: [
            {
              role: 'user',
              content: "Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:\n\nuser: Hello, AI!\nassistant: Hello! How can I help you today?\nuser: What is the weather?\nassistant: I cannot check the weather in real-time."
            }
          ],
          response_content: 'User asked about weather, AI explained limitations of real-time information.'
        )
      end

      it 'compacts the chat history with a summary' do
        expect(chat_thread.messages.all_values.length).to eq(4)
        call_action
        messages = chat_thread.messages.all_values
        expect(messages.length).to eq(1)
        expect(messages[0]).to have_attributes(
          role: :system,
          content: 'Previous conversation summary: User asked about weather, AI explained limitations of real-time information.'
        )
      end

      it 'replies with compact confirmation message' do
        expect(message).to receive(:reply).with('Chat history has been compacted with a summary.')
        call_action
      end

      it 'calls OpenAI API to generate summary' do
        call_action
      end
    end

    context 'when chat thread is empty' do
      it 'replies with no history message' do
        expect(message).to receive(:reply).with('No chat history to compact.')
        call_action
      end

      it 'keeps the chat thread empty' do
        expect(chat_thread.messages.all_values).to be_empty
        call_action
        expect(chat_thread.messages.all_values).to be_empty
      end

      it 'does not call OpenAI API' do
        expect { call_action }.not_to raise_error
      end
    end

    context 'with variations of /compact command' do
      [
        '/compact',
        '  /compact',
        '/compact  ',
        '  /compact  ',
        '/compact with extra text'
      ].each do |command_text|
        context "when body is '#{command_text}'" do
          let(:body) { command_text }

          before do
            chat_thread.messages.add(
              Ruboty::AiAgent::ChatMessage.new(
                role: :user,
                content: 'Test message'
              )
            )

            stub_openai_chat_completion_with_content(
              messages: [
                {
                  role: 'user',
                  content: "Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:\n\nuser: Test message"
                }
              ],
              response_content: 'User sent test message.'
            )
          end

          it 'matches and executes the compact command' do
            expect(message).to receive(:reply).with('Chat history has been compacted with a summary.')
            call_action
          end
        end
      end
    end

    context 'when command does not match /compact' do
      let(:body) { 'compact' }

      before do
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
          response_content: 'Did you mean to compact the chat history? Use /compact command.'
        )
      end

      it 'does not compact the chat thread' do
        initial_count = chat_thread.messages.all_values.length
        call_action
        expect(chat_thread.messages.all_values.length).to be > initial_count
      end

      it 'processes as normal chat message' do
        expect(message).to receive(:reply).with('Did you mean to compact the chat history? Use /compact command.')
        call_action
      end
    end

    context 'when OpenAI API fails' do
      before do
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'Test message'
          )
        )

        allow_any_instance_of(Ruboty::AiAgent::LLM::OpenAI).to receive(:complete).and_raise(StandardError.new('API Error'))
      end

      it 'handles error gracefully' do
        expect(message).to receive(:reply).with('エラーが発生しました: API Error')
        call_action
      end

      it 'does not modify chat thread on error' do
        initial_count = chat_thread.messages.all_values.length
        call_action
        expect(chat_thread.messages.all_values.length).to eq(initial_count)
      end
    end

    context 'after compacting, new conversation can continue with summary context' do
      it 'can continue conversation with summary context' do
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :user,
            content: 'Old conversation about weather'
          )
        )
        chat_thread.messages.add(
          Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: 'Weather response'
          )
        )

        stub_openai_chat_completion_with_content(
          messages: [
            {
              role: 'user',
              content: "Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:\n\nuser: Old conversation about weather\nassistant: Weather response"
            }
          ],
          response_content: 'User asked about weather, got response.'
        )

        expect(message).to receive(:reply).with('Chat history has been compacted with a summary.')
        call_action

        messages = chat_thread.messages.all_values
        expect(messages.length).to eq(1)
        expect(messages[0]).to have_attributes(
          role: :system,
          content: 'Previous conversation summary: User asked about weather, got response.'
        )

        second_message = Ruboty::Message.new(
          body: 'Tell me more about that',
          from: from,
          to: to,
          robot: robot
        )
        allow(second_message).to receive(:reply)
        allow(second_message).to receive(:[]).with(:body).and_return('Tell me more about that')

        second_action = Ruboty::AiAgent::Actions::Chat.new(second_message)
        allow(second_action).to receive(:database).and_return(database)
        allow(second_action).to receive(:robot).and_return(robot)

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: 'Previous conversation summary: User asked about weather, got response.' },
            { role: 'user', content: 'Tell me more about that' }
          ],
          response_content: 'Based on our previous weather discussion, I can provide more details.'
        )

        expect(second_message).to receive(:reply).with('Based on our previous weather discussion, I can provide more details.')
        second_action.call

        final_messages = database.chat_thread(from).messages.all_values
        expect(final_messages.length).to eq(3)
        expect(final_messages[0]).to have_attributes(role: :system)
        expect(final_messages[1]).to have_attributes(role: :user, content: 'Tell me more about that')
        expect(final_messages[2]).to have_attributes(role: :assistant, content: 'Based on our previous weather discussion, I can provide more details.')
      end
    end
  end
end
