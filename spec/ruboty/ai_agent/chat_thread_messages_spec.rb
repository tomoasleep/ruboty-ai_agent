# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::ChatThreadMessages do
  include ChatFactory
  include OpenAIMockHelper
  include EnvMockHelper

  let(:database) { create_database }
  let(:chat_thread) { database.chat_thread('test_thread') }
  let(:messages) { chat_thread.messages }

  let(:llm) { Ruboty::AiAgent::LLM::OpenAI.new(client: OpenAI::Client.new(api_key: ''), model: 'gpt-5-nano') }

  describe '#over_auto_compact_threshold?' do
    before do
      stub_env('AUTO_COMPACT_THRESHOLD' => '80')
    end

    context 'when no messages have token usage' do
      before do
        messages.add(Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello'))
        messages.add(Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Hi there'))
      end

      it 'returns false' do
        expect(messages).not_to be_over_auto_compact_threshold
      end
    end

    context 'when a message exceeds threshold' do
      let(:high_usage_token) { Ruboty::AiAgent::TokenUsage.new(total_tokens: 10_000, prompt_tokens: 8000, completion_tokens: 2000, token_limit: 12_000) }
      let(:message_with_high_usage) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Test', token_usage: high_usage_token) }

      before do
        messages.add(Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello'))
        messages.add(message_with_high_usage)
      end

      it 'returns true' do
        expect(messages).to be_over_auto_compact_threshold
      end
    end

    context 'when no message exceeds threshold' do
      let(:low_usage_token) { Ruboty::AiAgent::TokenUsage.new(total_tokens: 8000, prompt_tokens: 6000, completion_tokens: 2000, token_limit: 12_000) }
      let(:message_with_low_usage) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Test', token_usage: low_usage_token) }

      before do
        messages.add(Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello'))
        messages.add(message_with_low_usage)
      end

      it 'returns false' do
        expect(messages).not_to be_over_auto_compact_threshold
      end
    end
  end

  describe '#compact' do
    let(:chat_messages) do
      [
        Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello'),
        Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Hi there')
      ]
    end

    before do
      chat_messages.each { |msg| messages.add(msg) }

      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'system', content: "Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:\n" },
          *chat_messages
        ],
        response_content: 'This is a summary'
      )
    end

    context 'when messages exist' do
      it 'clears messages and adds summary' do
        messages.compact(llm:)

        result_messages = messages.all_values
        expect(result_messages).to match([
                                           an_object_having_attributes(role: :system, content: 'Previous conversation summary: This is a summary')
                                         ])
      end
    end

    context 'when assistant message has tool call' do
      let(:assistant_message) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Test', tool_call_id: 'call_123', tool_name: 'sample_tool') }
      let(:chat_messages) do
        [*super(), assistant_message]
      end

      it 'preserves the assistant message after summary' do
        messages.compact(llm:)

        result_messages = messages.all_values
        expect(result_messages).to match([
                                           an_object_having_attributes(role: :system, content: 'Previous conversation summary: This is a summary'),
                                           an_object_having_attributes(role: :assistant, content: 'Test', tool_call_id: 'call_123', tool_name: 'sample_tool')
                                         ])
      end
    end

    context 'when assistant message has no tool call' do
      let(:assistant_message) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Test') }
      let(:chat_messages) do
        [*super(), assistant_message]
      end

      it 'does not preserve the assistant message' do
        messages.compact(llm:)

        result_messages = messages.all_values
        expect(result_messages).to match([
                                           an_object_having_attributes(role: :system)
                                         ])
      end
    end

    context 'when no messages exist' do
      let(:empty_thread) { database.chat_thread('empty_thread') }
      let(:empty_messages) { empty_thread.messages }

      it 'does not perform any action' do
        empty_messages.compact(llm:)
        expect(empty_messages.all_values).to be_empty
      end
    end
  end

  describe '#summarize' do
    subject(:summarize_response) { messages.summarize(llm:) }

    before do
      messages.add(Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello'))
      messages.add(Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Hi there'))

      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'system', content: "Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:\n" },
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there' }
        ],
        response_content: 'Summary content'
      )
    end

    it 'calls LLM with proper summary prompt' do
      result = summarize_response

      expect(result).to eq('Summary content')
    end
  end
end
