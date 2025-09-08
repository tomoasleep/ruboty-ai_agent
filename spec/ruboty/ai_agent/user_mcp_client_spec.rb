# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::UserMcpClient do
  include DatabaseFactory
  include UserFactory

  let(:database) { create_database }
  let(:user) { create_user(database: database) }
  let(:mcp_name) { 'test_server' }

  before do
    # Create MCP configuration for the user
    configuration = Ruboty::AiAgent::McpConfiguration.new(
      name: mcp_name,
      transport: :http,
      url: 'http://localhost:3000',
      headers: {}
    )
    user.mcp_configurations.add(configuration)
  end

  subject(:user_mcp_client) do
    described_class.new(user: user, mcp_name: mcp_name)
  end

  describe '#list_tools' do
    let(:tools_data) { [{ 'name' => 'get_weather' }] }
    let(:mcp_name) { 'test_server' }
    let(:mock_http_client) { instance_double('HttpMcpClient') }

    before do
      allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(mock_http_client)
    end

    context 'when cache hit' do
      before do
        allow(mock_http_client).to receive(:list_tools)
        user.mcp_tools_caches.store_data(tools_data, key: mcp_name)
      end

      it 'returns cached data without calling mcp_client' do
        result = user_mcp_client.list_tools

        expect(result).to eq(tools_data)
        expect(mock_http_client).not_to have_received(:list_tools)
      end
    end

    context 'when cache miss' do
      before do
        allow(mock_http_client).to receive(:list_tools).and_return(tools_data)
      end

      it 'calls mcp_client and caches the result' do
        result = user_mcp_client.list_tools

        expect(result).to eq(tools_data)
        expect(mock_http_client).to have_received(:list_tools)
        expect(user.mcp_tools_caches.fetch_data(mcp_name)).to eq(tools_data)
      end
    end
  end

  describe '#call_tool' do
    let(:tool_name) { 'get_weather' }
    let(:arguments) { { location: 'Tokyo' } }
    let(:result) { 'Sunny, 25°C' }
    let(:mock_http_client) { instance_double('HttpMcpClient') }

    before do
      allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(mock_http_client)
      allow(mock_http_client).to receive(:call_tool)
        .with(tool_name, arguments)
        .and_return(result)
    end

    it 'delegates to mcp_client without caching' do
      returned_result = user_mcp_client.call_tool(tool_name, arguments)

      expect(returned_result).to eq(result)
      expect(mock_http_client).to have_received(:call_tool).with(tool_name, arguments)
    end
  end

  describe 'delegation methods' do
    let(:mock_http_client) { instance_double('HttpMcpClient') }

    before do
      allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(mock_http_client)
    end

    %i[list_prompts list_resources ping initialize_session cleanup_session].each do |method|
      it "delegates #{method} to mcp_client" do
        allow(mock_http_client).to receive(method)

        user_mcp_client.public_send(method)

        expect(mock_http_client).to have_received(method)
      end
    end

    it 'delegates get_prompt to mcp_client' do
      allow(mock_http_client).to receive(:get_prompt)

      user_mcp_client.get_prompt('test_prompt')

      expect(mock_http_client).to have_received(:get_prompt).with('test_prompt', {})
    end

    it 'delegates read_resource to mcp_client' do
      allow(mock_http_client).to receive(:read_resource)

      user_mcp_client.read_resource('file://test.txt')

      expect(mock_http_client).to have_received(:read_resource).with('file://test.txt')
    end
  end
end
