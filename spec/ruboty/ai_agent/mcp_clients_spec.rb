# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::McpClients do
  describe '#initialize' do
    context 'with empty clients' do
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

    context 'with user mcp clients' do
      subject(:mcp_clients) { described_class.new(clients) }

      let(:mock_client) { instance_double(Ruboty::AiAgent::UserMcpClient) }
      let(:clients) { [mock_client] }

      describe '#any?' do
        subject { mcp_clients.any? }

        it { is_expected.to be true }
      end
    end
  end

  describe '#available_tools' do
    subject(:mcp_clients) { described_class.new(clients) }

    let(:mock_client) { instance_double(Ruboty::AiAgent::UserMcpClient) }
    let(:clients) { [mock_client] }

    context 'when tools are available' do
      subject(:available_tools) { mcp_clients.available_tools }

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
        allow(mock_client).to receive(:list_tools).and_return(mcp_tools)
      end

      it 'returns tools as Tool objects' do
        tools = available_tools
        expect(tools.size).to eq(1)
        expect(tools.first).to be_a(Ruboty::AiAgent::Tool)
        expect(tools.first.name).to eq('get_weather')
        expect(tools.first.description).to eq('Get weather information')
      end
    end
  end

  describe '#execute_tool' do
    subject(:mcp_clients) { described_class.new(clients) }

    let(:mock_client) { instance_double(Ruboty::AiAgent::UserMcpClient) }
    let(:clients) { [mock_client] }

    context 'when tool exists' do
      subject(:execute_result) { mcp_clients.execute_tool('get_weather', location: 'Tokyo') }

      before do
        allow(mock_client).to receive(:list_tools).and_return([
                                                                { 'name' => 'get_weather' }
                                                              ])
        allow(mock_client).to receive(:call_tool)
          .with('get_weather', { location: 'Tokyo' })
          .and_return('Sunny, 25°C')
      end

      it { is_expected.to eq('Sunny, 25°C') }
    end

    context 'when tool does not exist' do
      subject(:execute_result) { mcp_clients.execute_tool('nonexistent_tool', {}) }

      before do
        allow(mock_client).to receive(:list_tools).and_return([])
      end

      it 'returns nil' do
        expect(execute_result).to be_nil
      end
    end
  end
end
