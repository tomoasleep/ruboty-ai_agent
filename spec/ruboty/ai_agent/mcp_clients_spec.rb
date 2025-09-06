# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::McpClients do
  include DatabaseFactory
  describe '#initialize' do
    context 'with empty servers' do
      subject(:mcp_clients) { described_class.new([]) }

      describe '#clients' do
        subject { mcp_clients.clients }
        it { is_expected.to be_empty }
      end

      describe '#any?' do
        subject { mcp_clients.any? }
        it { is_expected.to be false }
      end
    end

    context 'with http server config' do
      let(:mcp_configurations) do
        [
          create_mcp_configuration(
            name: 'test_server',
            transport: 'http',
            url: 'http://localhost:3000/mcp',
            headers: { 'Authorization' => 'Bearer token' }
          )
        ]
      end

      subject(:mcp_clients) { described_class.new(mcp_configurations) }

      before do
        allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(double('HttpClient'))
      end

      it 'creates http client' do
        mcp_clients
        expect(Ruboty::AiAgent::HttpMcpClient).to have_received(:new).with(
          url: 'http://localhost:3000/mcp',
          headers: { 'Authorization' => 'Bearer token' }
        )
      end

      describe '#any?' do
        subject { mcp_clients.any? }
        it { is_expected.to be true }
      end
    end

    context 'with stdio server config' do
      let(:mcp_configurations) do
        [
          create_mcp_configuration(
            name: 'stdio_server',
            transport: 'stdio'
          )
        ]
      end

      subject(:mcp_clients) { described_class.new(mcp_configurations) }

      it 'raises error for unsupported transport type' do
        expect { mcp_clients }.to raise_error('Unknown MCP server type: stdio')
      end
    end

    context 'with invalid server type' do
      let(:mcp_configurations) do
        [
          create_mcp_configuration(
            name: 'invalid_server',
            transport: 'invalid',
            url: 'http://localhost:3000'
          )
        ]
      end

      subject(:create_clients) { described_class.new(mcp_configurations) }

      it 'raises error for unknown transport type' do
        expect { create_clients }.to raise_error('Unknown MCP server type: invalid')
      end
    end
  end

  describe '#available_tools' do
    let(:http_client) { double('HttpClient') }
    let(:mcp_configurations) do
      [
        create_mcp_configuration(
          name: 'test_server',
          transport: 'http',
          url: 'http://localhost:3000'
        )
      ]
    end

    subject(:mcp_clients) { described_class.new(mcp_configurations) }

    before do
      allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(http_client)
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

      subject(:available_tools) { mcp_clients.available_tools }

      before do
        allow(http_client).to receive(:list_tools).and_return(mcp_tools)
      end

      it 'returns tools as Tool objects' do
        tools = available_tools
        expect(tools.size).to eq(1)
        expect(tools.first).to be_a(Ruboty::AiAgent::Tool)
        expect(tools.first.name).to eq('get_weather')
        expect(tools.first.description).to eq('Get weather information')
      end
    end

    context 'when client raises error' do
      subject(:available_tools) { mcp_clients.available_tools }

      before do
        allow(http_client).to receive(:list_tools).and_raise(StandardError.new('Connection failed'))
      end

      it 'raises the error' do
        expect { available_tools }.to raise_error(StandardError, 'Connection failed')
      end
    end
  end

  describe '#execute_tool' do
    let(:http_client) { double('HttpClient') }
    let(:mcp_configurations) do
      [
        create_mcp_configuration(
          name: 'test_server',
          transport: 'http',
          url: 'http://localhost:3000'
        )
      ]
    end

    subject(:mcp_clients) { described_class.new(mcp_configurations) }

    before do
      allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(http_client)
    end

    context 'when tool exists' do
      subject(:execute_result) { mcp_clients.execute_tool('get_weather', location: 'Tokyo') }

      before do
        allow(http_client).to receive(:list_tools).and_return([
                                                                { 'name' => 'get_weather' }
                                                              ])
        allow(http_client).to receive(:call_tool)
          .with('get_weather', { location: 'Tokyo' })
          .and_return('Sunny, 25°C')
      end

      it { is_expected.to eq('Sunny, 25°C') }
    end

    context 'when tool does not exist' do
      subject(:execute_result) { mcp_clients.execute_tool('nonexistent_tool', {}) }

      before do
        allow(http_client).to receive(:list_tools).and_return([])
      end

      it 'returns the clients array' do
        expect(execute_result).to eq([http_client])
      end
    end

    context 'when client raises error' do
      subject(:execute_result) { mcp_clients.execute_tool('get_weather', {}) }

      before do
        allow(http_client).to receive(:list_tools).and_raise(StandardError.new('Connection failed'))
      end

      it 'raises the error' do
        expect { execute_result }.to raise_error(StandardError, 'Connection failed')
      end
    end
  end
end
