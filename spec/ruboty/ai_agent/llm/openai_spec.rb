# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::LLM::OpenAI do
  subject(:llm) { described_class.new(client: client, model: model) }

  let(:client) { instance_double('OpenAI::Client') }
  let(:model) { 'gpt-4' }

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
      let(:openai_response) do
        double('OpenAI::Response',
               choices: [
                 double('Choice',
                        message: double('Message',
                                        role: 'assistant',
                                        content: 'Hi there!',
                                        tool_calls: nil))
               ])
      end

      before do
        allow(client).to receive_message_chain(:chat, :completions, :create).and_return(openai_response)
      end

      it 'sends correct messages to OpenAI API' do
        expect(client).to receive_message_chain(:chat, :completions, :create).with(
          model: 'gpt-4',
          messages: [
            { role: 'system', content: 'You are helpful' },
            { role: 'user', content: 'Hello' }
          ],
          tools: []
        )
        complete
      end

      it 'returns a Response with assistant message' do
        response = complete

        expect(response).to be_a(Ruboty::AiAgent::LLM::Response)
        expect(response.message.role).to eq('assistant')
        expect(response.message.content).to eq('Hi there!')
        expect(response.tool).to be_nil
        expect(response.tool_call_id).to be_nil
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
        let(:openai_response) do
          double('OpenAI::Response',
                 choices: [
                   double('Choice',
                          message: double('Message',
                                          role: 'assistant',
                                          content: nil,
                                          tool_calls: [
                                            double('ToolCall',
                                                   id: 'call_123',
                                                   function: double('Function',
                                                                    name: 'get_weather',
                                                                    arguments: '{"location": "Tokyo"}'))
                                          ]))
                 ])
        end

        before do
          allow(client).to receive_message_chain(:chat, :completions, :create).and_return(openai_response)
        end

        it 'sends tools to OpenAI API' do
          expect(client).to receive_message_chain(:chat, :completions, :create).with(
            model: 'gpt-4',
            messages: anything,
            tools: [
              {
                type: 'function',
                function: {
                  name: 'get_weather',
                  description: 'Get weather information',
                  parameters: {
                    'type' => 'object',
                    'properties' => {
                      'location' => { 'type' => 'string' }
                    },
                    'required' => ['location']
                  }
                }
              }
            ]
          )
          complete
        end

        it 'returns Response with tool call information' do
          response = complete

          aggregate_failures do
            expect(response.message.role).to eq('assistant')
            expect(response.message.content).to be_nil
            expect(response.message.tool_call_id).to eq('call_123')
            expect(response.message.tool_name).to eq('get_weather')
            expect(response.message.tool_arguments).to eq({ location: 'Tokyo' })
            expect(response.tool).to eq(tool)
            expect(response.tool_call_id).to eq('call_123')
            expect(response.tool_arguments).to eq({ location: 'Tokyo' })
          end
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

      let(:openai_response) do
        double('OpenAI::Response',
               choices: [
                 double('Choice',
                        message: double('Message',
                                        role: 'assistant',
                                        content: 'Final response',
                                        tool_calls: nil))
               ])
      end

      before do
        allow(client).to receive_message_chain(:chat, :completions, :create).and_return(openai_response)
      end

      it 'correctly formats all message types for OpenAI' do
        expect(client).to receive_message_chain(:chat, :completions, :create).with(
          model: 'gpt-4',
          messages: [
            { role: 'system', content: 'System prompt' },
            { role: 'user', content: 'User message' },
            {
              role: 'assistant',
              content: nil,
              tool_calls: [
                {
                  id: 'call_456',
                  type: 'function',
                  function: {
                    name: 'calculator',
                    arguments: '{"expression":"2+2"}'
                  }
                }
              ]
            },
            { role: 'tool', tool_call_id: 'call_456', content: '4' },
            { role: 'assistant', content: 'The answer is 4', tool_calls: nil }
          ],
          tools: []
        )
        complete
      end
    end

    context 'with invalid message role' do
      let(:messages) do
        [
          Ruboty::AiAgent::ChatMessage.new(role: :invalid, content: 'Invalid role')
        ]
      end

      before do
        # Allow the method chain to be called, but the error will be raised in message conversion
        allow(client).to receive_message_chain(:chat, :completions, :create)
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

      let(:openai_response) do
        double('OpenAI::Response',
               choices: [
                 double('Choice',
                        message: double('Message',
                                        role: 'assistant',
                                        content: 'Response',
                                        tool_calls: nil))
               ])
      end

      before do
        allow(client).to receive_message_chain(:chat, :completions, :create).and_return(openai_response)
      end

      it 'uses default empty schema' do
        expect(client).to receive_message_chain(:chat, :completions, :create).with(
          model: 'gpt-4',
          messages: anything,
          tools: [
            {
              type: 'function',
              function: {
                name: 'simple_tool',
                description: 'A simple tool',
                parameters: {
                  type: 'object',
                  properties: {},
                  required: []
                }
              }
            }
          ]
        )
        complete
      end
    end
  end
end
