# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  describe 'usage command' do
    include OpenAIMockHelper
    include McpMockHelper
    include RobotFactory

    subject(:receive_message) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

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
    let(:body) { '/usage' }

    def said_messages #: Array[Hash[untyped, untyped]]
      robot.adapter.messages
    end

    describe 'with /usage command' do
      let(:chat_thread) { database.chat_thread(from) }

      context 'when there is a message with token usage' do
        let(:token_usage) do
          Ruboty::AiAgent::TokenUsage.new(
            prompt_tokens: 1_000,
            completion_tokens: 500,
            total_tokens: 1_500,
            token_limit: 128_000
          )
        end

        before do
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'Hello!',
              token_usage: token_usage
            )
          )
        end

        it 'replies with formatted token usage information' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'Token usage: 1,000 (prompt) + 500 (completion) = 1,500 (total) / 128,000 (1.17%)'))
        end
      end

      context 'when there is a message with token usage but no token limit' do
        let(:token_usage) do
          Ruboty::AiAgent::TokenUsage.new(
            prompt_tokens: 750,
            completion_tokens: 250,
            total_tokens: 1_000
          )
        end

        before do
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'Hello!',
              token_usage: token_usage
            )
          )
        end

        it 'replies with token usage information without limit' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'Token usage: 750 (prompt) + 250 (completion) = 1,000 (total)'))
        end
      end

      context 'when there are no messages with token usage' do
        before do
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :user,
              content: 'Hello!'
            )
          )
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'Hi there!'
            )
          )
        end

        it 'replies with no token usage found message' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'No token usage information found.'))
        end
      end

      context 'when chat thread is empty' do
        it 'replies with no token usage found message' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'No token usage information found.'))
        end
      end

      context 'with variations of /usage command' do
        [
          '/usage',
          '  /usage',
          '/usage  ',
          '  /usage  ',
          '/usage with extra text'
        ].each do |command_text|
          context "when body is '#{command_text}'" do
            let(:body) { command_text }
            let(:token_usage) do
              Ruboty::AiAgent::TokenUsage.new(
                prompt_tokens: 100,
                completion_tokens: 50,
                total_tokens: 150,
                token_limit: 128_000
              )
            end

            before do
              chat_thread.messages.add(
                Ruboty::AiAgent::ChatMessage.new(
                  role: :assistant,
                  content: 'Response',
                  token_usage: token_usage
                )
              )
            end

            it 'matches and executes the usage command' do
              receive_message

              expect(said_messages).to include(a_hash_including(body: 'Token usage: 100 (prompt) + 50 (completion) = 150 (total) / 128,000 (0.12%)'))
            end
          end
        end
      end

      context 'when command does not match /usage' do
        let(:body) { 'usage' } # without slash

        before do
          stub_openai_chat_completion_with_content(
            messages: [
              { role: 'user', content: body }
            ],
            response_content: 'Did you mean to check token usage? Use /usage command.'
          )
        end

        it 'processes as normal chat message' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'Did you mean to check token usage? Use /usage command.'))
        end
      end

      context 'when there are multiple messages with token usage' do
        let(:older_token_usage) do
          Ruboty::AiAgent::TokenUsage.new(
            prompt_tokens: 200,
            completion_tokens: 100,
            total_tokens: 300,
            token_limit: 128_000
          )
        end

        let(:newer_token_usage) do
          Ruboty::AiAgent::TokenUsage.new(
            prompt_tokens: 500,
            completion_tokens: 300,
            total_tokens: 800,
            token_limit: 128_000
          )
        end

        before do
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'First response',
              token_usage: older_token_usage
            )
          )
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :user,
              content: 'Second message'
            )
          )
          chat_thread.messages.add(
            Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'Second response',
              token_usage: newer_token_usage
            )
          )
        end

        it 'shows the first message with token usage found' do
          receive_message

          expect(said_messages).to include(a_hash_including(body: 'Token usage: 200 (prompt) + 100 (completion) = 300 (total) / 128,000 (0.23%)'))
        end
      end
    end
  end
end
