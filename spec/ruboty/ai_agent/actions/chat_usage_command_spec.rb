# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  describe 'usage command' do
    include OpenAIMockHelper
    include McpMockHelper

    subject(:action) { described_class.new(message) }

    let(:robot) { Ruboty::Robot.new }
    let(:brain) { robot.brain }
    let(:database) { Ruboty::AiAgent::Database.new(brain) }

    let(:from) { 'test_user' }
    let(:to) { 'ruboty' }
    let(:body) { '/usage' }

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
      allow(message).to have_received(:reply)
      allow(message).to have_received(:[]).with(:body).and_return(body)
      message
    end

    before do
      # Stub ENV variables
      allow(ENV).to have_received(:fetch).and_call_original
      allow(ENV).to have_received(:fetch).with('OPENAI_API_KEY', nil).and_return('test_api_key')
      allow(ENV).to have_received(:fetch).with('OPENAI_MODEL', 'gpt-5-nano').and_return('gpt-5')
      allow(ENV).to have_received(:[]).and_call_original
      allow(ENV).to have_received(:[]).with('DEBUG').and_return(nil)
      allow(ENV).to have_received(:[]).with('OPENAI_ORG_ID').and_return(nil)

      # Allow action to use real database
      allow(action).to receive_messages(database: database, robot: robot)
    end

    describe '#call with /usage command' do
      subject(:call_action) { action.call }

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
          expected_text = 'Token usage: 1,000 (prompt) + 500 (completion) = 1,500 (total) / 128,000 (1.17%)'
          expect(message).to have_received(:reply).with(expected_text)
          call_action
        end

        it 'does not call OpenAI API' do
          expect { call_action }.not_to raise_error
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
          expected_text = 'Token usage: 750 (prompt) + 250 (completion) = 1,000 (total)'
          expect(message).to have_received(:reply).with(expected_text)
          call_action
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
          expect(message).to have_received(:reply).with('No token usage information found.')
          call_action
        end
      end

      context 'when chat thread is empty' do
        it 'replies with no token usage found message' do
          expect(message).to have_received(:reply).with('No token usage information found.')
          call_action
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
              expected_text = 'Token usage: 100 (prompt) + 50 (completion) = 150 (total) / 128,000 (0.12%)'
              expect(message).to have_received(:reply).with(expected_text)
              call_action
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
          expect(message).to have_received(:reply).with('Did you mean to check token usage? Use /usage command.')
          call_action
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
          expected_text = 'Token usage: 200 (prompt) + 100 (completion) = 300 (total) / 128,000 (0.23%)'
          expect(message).to have_received(:reply).with(expected_text)
          call_action
        end
      end
    end
  end
end
