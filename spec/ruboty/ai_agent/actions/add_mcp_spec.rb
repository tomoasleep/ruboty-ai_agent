# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::AddMcp do
  include RobotFactory
  include McpMockHelper

  subject(:call_robot) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

  let(:robot) { create_robot(env:) }
  let(:database) { Ruboty::AiAgent::Database.new(robot.brain) }
  let(:env) do
    {
      'OPENAI_API_KEY' => 'test_api_key',
      'OPENAI_MODEL' => 'gpt-5-nano'
    }
  end
  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }

  def said_messages
    robot.adapter.messages
  end

  describe 'adding a new MCP server with --bearer-token option' do
    let(:body) { 'add mcp test --transport http --bearer-token my_secret_token https://example.com/mcp' }

    it 'adds the MCP server with Authorization header' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: include('Added MCP configuration test')
        )
      )

      expect(database.user(from).mcp_configurations.fetch('test')).to be_a(Ruboty::AiAgent::McpConfiguration)
        .and(have_attributes(name: 'test', transport: :http, url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer my_secret_token' }))
    end
  end

  describe 'adding a new MCP server with --header option' do
    let(:body) { 'add mcp test --transport http --header "Authorization: Bearer manual_token" https://example.com/mcp' }

    before do
      stub_mcp_initialize(base_url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer manual_token' })
    end

    it 'adds the MCP server with manual Authorization header' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: include('Added MCP configuration test')
        )
      )

      expect(database.user(from).mcp_configurations.fetch('test')).to be_a(Ruboty::AiAgent::McpConfiguration)
        .and(have_attributes(name: 'test', transport: :http, url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer manual_token' }))
    end
  end

  describe 'adding a new MCP server with both --bearer-token and --header Authorization' do
    let(:body) { 'add mcp test --transport http --header "Authorization: Bearer manual_token" --bearer-token bearer_token https://example.com/mcp' }

    before do
      stub_mcp_initialize(base_url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer bearer_token' })
    end

    it 'uses --bearer-token (last option wins)' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: include('Added MCP configuration test')
        )
      )

      expect(database.user(from).mcp_configurations.fetch('test')).to be_a(Ruboty::AiAgent::McpConfiguration)
        .and(have_attributes(name: 'test', transport: :http, url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer bearer_token' }))
    end
  end

  describe 'adding a new MCP server with --bearer-token and other headers' do
    let(:body) { 'add mcp test --transport http --bearer-token my_token --header "X-Custom-Header: custom_value" https://example.com/mcp' }

    before do
      stub_mcp_initialize(base_url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer my_token', 'X-Custom-Header' => 'custom_value' })
    end

    it 'includes both Authorization and custom headers' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: include('Added MCP configuration test')
        )
      )

      expect(database.user(from).mcp_configurations.fetch('test')).to be_a(Ruboty::AiAgent::McpConfiguration)
        .and(have_attributes(name: 'test', transport: :http, url: 'https://example.com/mcp', headers: { 'Authorization' => 'Bearer my_token', 'X-Custom-Header' => 'custom_value' }))
    end
  end

  describe 'adding a new MCP server without token' do
    let(:body) { 'add mcp test --transport http https://example.com/mcp' }

    before do
      stub_mcp_initialize(base_url: 'https://example.com/mcp')
    end

    it 'adds the MCP server without Authorization header' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: include('Added MCP configuration test')
        )
      )
    end
  end

  describe 'error handling for missing URL with --bearer-token' do
    let(:body) { 'add mcp test --transport http --bearer-token my_token' }

    it 'returns an error message about missing URL' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: 'Error: URL is required for HTTP transport. Please specify the URL as an argument.'
        )
      )
    end
  end
end
