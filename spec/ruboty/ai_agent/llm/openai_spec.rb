# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::LLM::OpenAI do
  include OpenAIMockHelper

  subject(:llm) { described_class.new(client: client, model: model) }

  let(:client) { ::OpenAI::Client.new(api_key: 'test_token') }
  let(:model) { 'gpt-5' }

  describe '#initialize' do
    it 'sets client and model' do
      expect(llm.client).to eq(client)
      expect(llm.model).to eq(model)
    end
  end

  describe '#complete' do
    subject(:complete) { llm.complete(messages: messages, tools: tools) }

    let(:messages) do
      [
        Ruboty::AiAgent::ChatMessage.new(role: :system, content: 'You are helpful'),
        Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello')
      ]
    end
    let(:tools) { [] }

    context 'without tools' do
      before do
        stub_openai_chat_completion_with_content(
          model:,
          messages: messages,
          tools: tools,
          response_content: 'Hi there!'
        )
      end

      it 'returns a Response with assistant message' do
        response = complete

        expect(response).to be_a(Ruboty::AiAgent::LLM::Response)
        expect(response.message.role).to eq(:assistant)
        expect(response.message.content).to eq('Hi there!')
        expect(response.tool).to be_nil
        expect(response.tool_call_id).to be_nil
      end

      it 'includes token usage information in the response' do
        response = complete

        expect(response.message.token_usage).to be_a(Ruboty::AiAgent::TokenUsage)
        expect(response.message.token_usage.prompt_tokens).to eq(50)
        expect(response.message.token_usage.completion_tokens).to eq(20)
        expect(response.message.token_usage.total_tokens).to eq(70)
        expect(response.message.token_usage.token_limit).to eq(400_000)
      end
    end

    context 'with tools' do
      let(:tool) do
        Ruboty::AiAgent::Tool.new(
          name: 'get_weather',
          title: 'Weather Tool',
          description: 'Get weather information',
          input_schema: {
            'type' => 'object',
            'properties' => {
              'location' => { 'type' => 'string' }
            },
            'required' => ['location']
          }
        )
      end
      let(:tools) { [tool] }

      context 'when assistant uses a tool' do
        before do
          stub_openai_chat_completion_with_tool_call(
            model:,
            messages: messages,
            tools: tools,
            tool_name: 'get_weather',
            tool_arguments: { location: 'Tokyo' },
            tool_call_id: 'call_123'
          )
        end

        it 'returns Response with tool call information' do
          response = complete

          expect(response.message.role).to eq(:assistant)
          expect(response.message.content).to be_empty
          expect(response.message.tool_call_id).to eq('call_123')
          expect(response.message.tool_name).to eq('get_weather')
          expect(response.message.tool_arguments).to eq({ location: 'Tokyo' })
        end
      end
    end

    context 'with various message types' do
      let(:messages) do
        [
          Ruboty::AiAgent::ChatMessage.new(role: :system, content: 'System prompt'),
          Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'User message'),
          Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: nil,
            tool_call_id: 'call_456',
            tool_name: 'calculator',
            tool_arguments: { expression: '2+2' }
          ),
          Ruboty::AiAgent::ChatMessage.new(
            role: :tool,
            content: '4',
            tool_call_id: 'call_456'
          ),
          Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'The answer is 4')
        ]
      end

      before do
        stub_openai_chat_completion_with_content(
          model:,
          messages: messages,
          response_content: 'Final response'
        )
      end

      it 'returns a Response with assistant message' do
        response = complete
        expect(response.message.content).to eq('Final response')
      end
    end

    context 'with invalid message role' do
      let(:messages) do
        [
          Ruboty::AiAgent::ChatMessage.new(role: :invalid, content: 'Invalid role')
        ]
      end

      it 'raises an error' do
        expect { complete }.to raise_error(
          RuntimeError,
          'Unknown message role: invalid'
        )
      end
    end

    context 'when tool has no input schema' do
      let(:tool) do
        Ruboty::AiAgent::Tool.new(
          name: 'simple_tool',
          title: 'Simple Tool',
          description: 'A simple tool',
          input_schema: nil
        )
      end
      let(:tools) { [tool] }

      before do
        stub_openai_chat_completion_with_content(
          model:,
          messages: messages,
          tools: tools,
          response_content: 'Response'
        )
      end

      it 'uses default empty schema' do
        response = complete
        expect(response.message.content).to eq('Response')
      end
    end
  end
end
