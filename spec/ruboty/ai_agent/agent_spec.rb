# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Ruboty::AiAgent::Agent do
  let(:client) { double('OpenAI::Client') }
  let(:model) { 'gpt-4o' }
  let(:system_prompt) { 'You are a helpful assistant.' }
  let(:messages) { [] }
  let(:mcp_servers) { [] }
  
  subject(:agent) do
    described_class.new(
      client: client,
      messages: messages,
      system_prompt: system_prompt,
      mcp_servers: mcp_servers,
      model: model
    )
  end

  describe '#initialize' do
    context 'with no existing messages' do
      it 'initializes with system prompt as first message' do
        expect(agent.messages.first).to eq({ role: 'system', content: system_prompt })
      end
    end

    context 'with existing messages that include system prompt' do
      let(:messages) do
        [
          { role: 'system', content: 'Previous system prompt' },
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there!' }
        ]
      end

      it 'preserves existing messages' do
        expect(agent.messages).to eq(messages)
      end

      it 'does not add another system prompt' do
        system_messages = agent.messages.select { |m| m[:role] == 'system' }
        expect(system_messages.count).to eq(1)
      end
    end

    context 'with messages but no system prompt at beginning' do
      let(:messages) do
        [
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there!' }
        ]
      end

      it 'adds system prompt at the beginning' do
        expect(agent.messages.first).to eq({ role: 'system', content: system_prompt })
        expect(agent.messages[1..]).to eq(messages)
      end
    end
  end

  describe '#chat' do
    let(:user_input) { 'What is the weather today?' }
    let(:assistant_response) { 'I cannot access real-time weather information.' }
    let(:api_response) do
      {
        'choices' => [
          {
            'message' => {
              'role' => 'assistant',
              'content' => assistant_response
            }
          }
        ]
      }
    end

    before do
      allow(client).to receive(:chat).with(parameters: anything).and_return(api_response)
    end

    it 'sends user input to OpenAI API' do
      agent.chat(user_input)
      
      expect(client).to have_received(:chat).with(parameters: hash_including(
        messages: array_including(
          hash_including(role: 'user', content: user_input)
        )
      ))
    end

    it 'returns the assistant response' do
      response = agent.chat(user_input)
      expect(response).to eq(assistant_response)
    end

    it 'adds both user and assistant messages to history' do
      initial_message_count = agent.messages.count
      agent.chat(user_input)
      
      expect(agent.messages.count).to eq(initial_message_count + 2)
      expect(agent.messages[-2]).to eq({ role: 'user', content: user_input })
      expect(agent.messages[-1]).to include(
        'role' => 'assistant',
        'content' => assistant_response
      )
    end

    context 'with streaming' do
      let(:chunks) do
        [
          { 'choices' => [{ 'delta' => { 'content' => 'I cannot ' } }] },
          { 'choices' => [{ 'delta' => { 'content' => 'access ' } }] },
          { 'choices' => [{ 'delta' => { 'content' => 'real-time weather.' } }] }
        ]
      end

      it 'yields content chunks to the block' do
        allow(client).to receive(:chat) do |parameters:|
          stream_proc = parameters[:stream]
          chunks.each { |chunk| stream_proc.call(chunk, nil) }
          nil
        end

        collected_chunks = []
        agent.chat(user_input, stream: true) do |chunk|
          collected_chunks << chunk
        end

        expect(collected_chunks).to eq(['I cannot ', 'access ', 'real-time weather.'])
      end
    end

    context 'with tool calls' do
      let(:mcp_servers) do
        [{
          type: 'http',
          url: 'http://localhost:3000/mcp'
        }]
      end

      let(:tool_response) do
        {
          'choices' => [
            {
              'message' => {
                'role' => 'assistant',
                'content' => nil,
                'tool_calls' => [
                  {
                    'id' => 'call_123',
                    'function' => {
                      'name' => 'get_weather',
                      'arguments' => '{"location": "Tokyo"}'
                    }
                  }
                ]
              }
            }
          ]
        }
      end

      let(:final_response) do
        {
          'choices' => [
            {
              'message' => {
                'role' => 'assistant',
                'content' => 'The weather in Tokyo is sunny and 25°C.'
              }
            }
          ]
        }
      end

      before do
        mcp_client = double('Mcp::HttpClient')
        allow(Mcp::HttpClient).to receive(:new).and_return(mcp_client)
        allow(mcp_client).to receive(:list_tools).and_return([
          {
            'name' => 'get_weather',
            'description' => 'Get the current weather',
            'inputSchema' => {
              'type' => 'object',
              'properties' => {
                'location' => { 'type' => 'string' }
              },
              'required' => ['location']
            }
          }
        ])

        allow(mcp_client).to receive(:call_tool)
          .with('get_weather', location: 'Tokyo')
          .and_return('Sunny, 25°C')

        allow(client).to receive(:chat)
          .and_return(tool_response, final_response)
      end

      xit 'handles tool calls and returns final response' do
        response = agent.chat(user_input)
        expect(response).to eq('The weather in Tokyo is sunny and 25°C.')
      end
    end

    context 'with API error' do
      before do
        error = Class.new(StandardError)
        error.define_method(:is_a?) { |klass| klass.name == 'Faraday::Error' }
        allow(client).to receive(:chat).and_raise(error.new('API Error'))
      end

      it 'raises an error with appropriate message' do
        expect { agent.chat(user_input) }.to raise_error(StandardError, 'API Error')
      end
    end
  end

  describe '#messages' do
    let(:messages) do
      [
        { role: 'user', content: 'Hello' },
        { role: 'assistant', content: 'Hi!' }
      ]
    end

    it 'returns current conversation history' do
      expect(agent.messages).to include(hash_including(role: 'user', content: 'Hello'))
    end

    it 'can be used to persist conversation state' do
      allow(client).to receive(:chat).and_return(
        { 'choices' => [{ 'message' => { 'role' => 'assistant', 'content' => 'Test response' } }] }
      )
      agent.chat('Test message')
      
      # Create new agent with saved messages
      new_agent = described_class.new(
        client: client,
        messages: agent.messages,
        model: model
      )
      
      expect(new_agent.messages).to eq(agent.messages)
    end
  end
end