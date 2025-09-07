# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::ShowUsage do
  describe '#call' do
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
      allow(message).to receive(:reply)
      message
    end

    before do
      # Allow action to use real database
      allow(action).to receive(:database).and_return(database)
      allow(action).to receive(:robot).and_return(robot)
    end

    context 'when there is a message with token usage' do
      let(:token_usage) do
        Ruboty::AiAgent::TokenUsage.new(
          prompt_tokens: 50,
          completion_tokens: 20,
          total_tokens: 70,
          token_limit: 128_000
        )
      end

      before do
        # Add messages to the chat thread using the real database
        database.user(from)
        chat_thread = database.chat_thread(from)

        # Add a message without token usage first
        chat_thread.messages << Ruboty::AiAgent::ChatMessage.new(
          role: :user,
          content: 'Hello'
        )

        # Add a message with token usage
        chat_thread.messages << Ruboty::AiAgent::ChatMessage.new(
          role: :assistant,
          content: 'Hello! How can I help you?',
          token_usage: token_usage
        )
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
    end

    context 'when there is a message with token usage but no token limit' do
      let(:token_usage) do
        Ruboty::AiAgent::TokenUsage.new(
          prompt_tokens: 50,
          completion_tokens: 20,
          total_tokens: 70
        )
      end

      before do
        database.user(from)
        chat_thread = database.chat_thread(from)

        chat_thread.messages << Ruboty::AiAgent::ChatMessage.new(
          role: :assistant,
          content: 'Hello! How can I help you?',
          token_usage: token_usage
        )
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

    context 'when there is no message with token usage' do
      before do
        database.user(from)
        chat_thread = database.chat_thread(from)

        chat_thread.messages << Ruboty::AiAgent::ChatMessage.new(
          role: :user,
          content: 'Hello'
        )
      end

      it 'replies with no usage information message' do
        action.call

        expect(message).to have_received(:reply).with('No token usage information found in the conversation history.')
      end
    end

    context 'when there are no messages' do
      it 'replies with no usage information message' do
        action.call

        expect(message).to have_received(:reply).with('No token usage information found in the conversation history.')
      end
    end
  end
end
