# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::McpClients do
  describe '#initialize' do
    context 'with empty servers' do
      subject(:mcp_clients) { described_class.new([]) }

      it 'initializes with no clients' do
        expect(mcp_clients.clients).to be_empty
      end

      it 'returns false for any?' do
        expect(mcp_clients.any?).to be false
      end
    end

    context 'with http server config' do
      let(:mcp_servers) do
        [{
          type: 'http',
          url: 'http://localhost:3000/mcp',
          headers: { 'Authorization' => 'Bearer token' }
        }]
      end

      subject(:mcp_clients) { described_class.new(mcp_servers) }

      before do
        allow(Mcp::HttpClient).to receive(:new).and_return(double('HttpClient'))
      end

      it 'creates http client' do
        expect(Mcp::HttpClient).to have_received(:new).with(
          url: 'http://localhost:3000/mcp',
          headers: { 'Authorization' => 'Bearer token' }
        )
      end

      it 'returns true for any?' do
        expect(mcp_clients.any?).to be true
      end
    end

    context 'with stdio server config' do
      let(:mcp_servers) do
        [{
          type: 'stdio',
          command: 'python',
          args: ['-m', 'weather_mcp']
        }]
      end

      subject(:mcp_clients) { described_class.new(mcp_servers) }

      before do
        allow(Mcp::StdioClient).to receive(:new).and_return(double('StdioClient'))
      end

      it 'creates stdio client' do
        expect(Mcp::StdioClient).to have_received(:new).with(
          command: 'python',
          args: ['-m', 'weather_mcp']
        )
      end
    end

    context 'with invalid server type' do
      let(:mcp_servers) do
        [{
          type: 'invalid',
          url: 'http://localhost:3000'
        }]
      end

      it 'handles initialization error gracefully' do
        expect { described_class.new(mcp_servers) }.not_to raise_error
      end

      it 'returns empty clients on error' do
        mcp_clients = described_class.new(mcp_servers)
        expect(mcp_clients.clients).to be_empty
      end
    end
  end

  describe '#available_tools' do
    let(:http_client) { double('HttpClient') }
    let(:mcp_servers) { [{ type: 'http', url: 'http://localhost:3000' }] }

    subject(:mcp_clients) { described_class.new(mcp_servers) }

    before do
      allow(Mcp::HttpClient).to receive(:new).and_return(http_client)
    end

    context 'when tools are available' do
      let(:mcp_tools) do
        [
          {
            'name' => 'get_weather',
            'description' => 'Get weather information',
            'inputSchema' => {
              'type' => 'object',
              'properties' => {
                'location' => { 'type' => 'string' }
              },
              'required' => ['location']
            }
          }
        ]
      end

      before do
        allow(http_client).to receive(:list_tools).and_return(mcp_tools)
      end

      it 'returns tools in OpenAI format' do
        tools = mcp_clients.available_tools
        expect(tools).to eq([
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
        ])
      end
    end

    context 'when client raises error' do
      before do
        allow(http_client).to receive(:list_tools).and_raise(StandardError.new('Connection failed'))
      end

      it 'returns empty array and prints warning' do
        expect { mcp_clients.available_tools }.to output(/Warning: Failed to fetch tools/).to_stdout
        expect(mcp_clients.available_tools).to eq([])
      end
    end
  end

  describe '#execute_tool' do
    let(:http_client) { double('HttpClient') }
    let(:mcp_servers) { [{ type: 'http', url: 'http://localhost:3000' }] }

    subject(:mcp_clients) { described_class.new(mcp_servers) }

    before do
      allow(Mcp::HttpClient).to receive(:new).and_return(http_client)
    end

    context 'when tool exists' do
      before do
        allow(http_client).to receive(:list_tools).and_return([
          { 'name' => 'get_weather' }
        ])
        allow(http_client).to receive(:call_tool)
          .with('get_weather', location: 'Tokyo')
          .and_return('Sunny, 25°C')
      end

      it 'executes the tool and returns result' do
        result = mcp_clients.execute_tool('get_weather', location: 'Tokyo')
        expect(result).to eq('Sunny, 25°C')
      end
    end

    context 'when tool does not exist' do
      before do
        allow(http_client).to receive(:list_tools).and_return([])
      end

      it 'returns error message' do
        result = mcp_clients.execute_tool('nonexistent_tool', {})
        expect(result).to eq('Tool nonexistent_tool not found or execution failed')
      end
    end

    context 'when client raises error' do
      before do
        allow(http_client).to receive(:list_tools).and_raise(StandardError.new('Connection failed'))
      end

      it 'returns error message and prints warning' do
        expect { mcp_clients.execute_tool('get_weather', {}) }.to output(/Error executing tool/).to_stdout
        result = mcp_clients.execute_tool('get_weather', {})
        expect(result).to eq('Tool get_weather not found or execution failed')
      end
    end
  end
end