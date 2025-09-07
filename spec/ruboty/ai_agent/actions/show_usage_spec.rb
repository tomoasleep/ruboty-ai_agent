# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::ShowUsage do
  describe '#call' do
    subject(:action) { described_class.new(message) }

    let(:robot) { Ruboty::Robot.new }
    let(:from) { 'test_user' }
    let(:to) { 'ruboty' }
    let(:body) { '/usage' }
    let(:room) { 'general' }

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
      message
    end

    let(:chat_thread) { instance_double('Ruboty::AiAgent::ChatThread') }
    let(:chat_thread_messages) { instance_double('Ruboty::AiAgent::ChatThreadMessages') }

    before do
      allow(action).to receive(:chat_thread).and_return(chat_thread)
      allow(chat_thread).to receive(:messages).and_return(chat_thread_messages)
    end

    context 'when there is a message with token usage' do
      let(:token_usage) { { prompt_tokens: 50, completion_tokens: 20, total_tokens: 70 } }
      let(:token_limit) { 128_000 }
      let(:message_with_usage) do
        instance_double('Ruboty::AiAgent::ChatMessage', token_usage: token_usage, token_limit: token_limit)
      end
      let(:message_without_usage) do
        instance_double('Ruboty::AiAgent::ChatMessage', token_usage: nil)
      end
      let(:messages) { [message_without_usage, message_with_usage] }

      before do
        allow(chat_thread_messages).to receive(:all_values).and_return(messages)
      end

      it 'replies with formatted token usage' do
        action.call

        expected_message = [
          'Token Usage:',
          '- Prompt tokens: 50',
          '- Completion tokens: 20',
          '- Total tokens: 70',
          '- Token limit: 128,000',
          '- Usage: 0.05%'
        ].join("\n")

        expect(message).to have_received(:reply).with(expected_message)
      end

      context 'when token limit is not available' do
        let(:message_with_usage) do
          instance_double('Ruboty::AiAgent::ChatMessage', token_usage: token_usage, token_limit: nil)
        end

        it 'replies with formatted token usage without limit information' do
          action.call

          expected_message = [
            'Token Usage:',
            '- Prompt tokens: 50',
            '- Completion tokens: 20',
            '- Total tokens: 70'
          ].join("\n")

          expect(message).to have_received(:reply).with(expected_message)
        end
      end
    end

    context 'when there is no message with token usage' do
      let(:message_without_usage) do
        instance_double('Ruboty::AiAgent::ChatMessage', token_usage: nil)
      end
      let(:messages) { [message_without_usage] }

      before do
        allow(chat_thread_messages).to receive(:all_values).and_return(messages)
      end

      it 'replies with no usage information message' do
        action.call

        expect(message).to have_received(:reply).with('No token usage information found in the conversation history.')
      end
    end

    context 'when there are no messages' do
      let(:messages) { [] }

      before do
        allow(chat_thread_messages).to receive(:all_values).and_return(messages)
      end

      it 'replies with no usage information message' do
        action.call

        expect(message).to have_received(:reply).with('No token usage information found in the conversation history.')
      end
    end
  end
end
