# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  describe 'compact command' do
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
    let(:body) { '/compact' }
    let(:model) { 'gpt-5-nano' }

    def said_messages
      robot.adapter.messages
    end

    def compact_command_message
      {
        role: 'system',
        content: <<~TEXT
          Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:
        TEXT
      }
    end

    def stub_compact(response_content:, messages: [])
      stub_openai_chat_completion_with_content(
        model:,
        messages: [
          compact_command_message,
          *messages
        ],
        response_content:
      )
    end

    describe 'with /compact command' do
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

          stub_compact(
            messages: chat_thread.messages.all_values.map { |m| { role: m.role.to_s, content: m.content } },
            response_content: 'User asked about weather, AI explained limitations of real-time information.'
          )
        end

        it 'compacts the chat history with a summary' do
          expect(chat_thread.messages.all_values.length).to eq(4)
          call_robot
          messages = chat_thread.messages.all_values
          expect(messages.length).to eq(1)
          expect(messages[0]).to have_attributes(
            role: :system,
            content: 'Previous conversation summary: User asked about weather, AI explained limitations of real-time information.'
          )
        end

        it 'replies with compact confirmation message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Chat history has been compacted with a summary.'))
        end
      end

      context 'when chat thread is empty' do
        it 'replies with no history message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'No chat history to compact.'))
        end

        it 'keeps the chat thread empty' do
          expect(chat_thread.messages.all_values).to be_empty
          call_robot
          expect(chat_thread.messages.all_values).to be_empty
        end

        it 'does not call OpenAI API' do
          expect { call_robot }.not_to raise_error
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

              stub_compact(
                messages: chat_thread.messages.all_values.map { |m| { role: m.role.to_s, content: m.content } },
                response_content: 'User sent test message.'
              )
            end

            it 'matches and executes the compact command' do
              call_robot
              expect(said_messages).to include(a_hash_including(body: 'Chat history has been compacted with a summary.'))
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
            model:,
            messages: [
              { role: 'user', content: 'Previous message' },
              { role: 'user', content: body }
            ],
            response_content: 'Did you mean to compact the chat history? Use /compact command.'
          )
        end

        it 'does not compact the chat thread' do
          initial_count = chat_thread.messages.all_values.length
          call_robot
          expect(chat_thread.messages.all_values.length).to be > initial_count
        end

        it 'processes as normal chat message' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Did you mean to compact the chat history? Use /compact command.'))
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

          stub_openai_chat_completion_with_error(
            model:,
            messages: [
              compact_command_message,
              {
                role: 'user',
                content: 'Test message'
              }
            ]
          )
        end

        it 'handles error gracefully' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'エラーが発生しました: Internal server error'))
        end

        it 'does not modify chat thread on error' do
          initial_count = chat_thread.messages.all_values.length
          call_robot
          expect(chat_thread.messages.all_values.length).to eq(initial_count)
        end
      end

      context 'when conversation continues after compacting' do
        subject(:call_robot_second) do
          stub_openai_chat_completion_with_content(
            messages: [
              { role: 'system', content: 'Previous conversation summary: User asked about weather, got response.' },
              { role: 'user', content: 'Tell me more about that' }
            ],
            response_content: 'Based on our previous weather discussion, I can provide more details.'
          )

          robot.receive(body: "#{robot.name} Tell me more about that", from:, to:)
        end

        before do
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

          stub_compact(
            messages: [
              { role: 'user', content: 'Old conversation about weather' },
              { role: 'assistant', content: 'Weather response' }
            ],
            response_content: 'User asked about weather, got response.'
          )
        end

        it 'can continue conversation with summary context' do
          call_robot
          expect(said_messages).to include(a_hash_including(body: 'Chat history has been compacted with a summary.'))
          expect(chat_thread.messages.all_values).to match([
                                                             have_attributes(
                                                               role: :system,
                                                               content: 'Previous conversation summary: User asked about weather, got response.'
                                                             )
                                                           ])

          call_robot_second
          expect(said_messages).to include(a_hash_including(body: 'Based on our previous weather discussion, I can provide more details.'))
          expect(chat_thread.messages.all_values).to match([
                                                             have_attributes(role: :system),
                                                             have_attributes(role: :user, content: 'Tell me more about that'),
                                                             have_attributes(role: :assistant, content: 'Based on our previous weather discussion, I can provide more details.')
                                                           ])
        end
      end
    end
  end
end
