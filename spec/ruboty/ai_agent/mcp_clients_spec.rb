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
        allow(mock_client).to receive_messages(list_tools: mcp_tools, mcp_name: 'weather_service')
      end

      it 'returns tools as Tool objects with prefixed names' do
        tools = available_tools
        expect(tools.size).to eq(1)
        expect(tools.first).to be_a(Ruboty::AiAgent::Tool)
        expect(tools.first.name).to eq('mcp_weather_service__get_weather')
        expect(tools.first.description).to eq('Get weather information')
      end
    end
  end
end
