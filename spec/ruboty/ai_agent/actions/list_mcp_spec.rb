# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::ListMcp do
  include RobotFactory
  include UserFactory
  include McpMockHelper

  subject(:call_robot) { robot.receive(body: "#{robot.name} list mcps", from: 'test_user', to: 'ruboty') }

  let(:robot) { create_robot(env: env) }
  let(:env) do
    {
      'OPENAI_API_KEY' => 'test_api_key',
      'OPENAI_MODEL' => 'gpt-5-nano'
    }
  end

  def said_messages
    robot.adapter.messages
  end

  describe 'list mcps command' do
    context 'when no MCP servers are configured' do
      it 'replies with no servers message' do
        call_robot
        expect(said_messages).to include(
          a_hash_including(
            body: 'No MCP servers found.'
          )
        )
      end
    end

    context 'when MCP servers are configured but have no tools' do
      before do
        database = Ruboty::AiAgent::Database.new(robot.brain)
        create_user(database: database, id: 'test_user')
        create_mcp_configuration(database: database, user_id: 'test_user', name: 'test_server', url: 'http://example.com')
        stub_mcp_initialize(base_url: 'http://example.com')
        stub_mcp_list_tools(base_url: 'http://example.com', tools: [])
      end

      it 'replies with server configuration only' do
        call_robot
        expected_output = <<~OUTPUT.chomp
          test_server:
            Transport: http
            URL: http://example.com
            Headers: {}
        OUTPUT
        expect(said_messages).to include(
          a_hash_including(
            body: expected_output
          )
        )
      end
    end

    context 'when MCP servers are configured with tools' do
      before do
        database = Ruboty::AiAgent::Database.new(robot.brain)
        create_user(database: database, id: 'test_user')
        create_mcp_configuration(database: database, user_id: 'test_user', name: 'test_server', url: 'http://example.com')
        stub_mcp_initialize(base_url: 'http://example.com')
      end

      context 'with tools having normal descriptions' do
        before do
          stub_mcp_list_tools(
            base_url: 'http://example.com',
            tools: [
              { 'name' => 'get_weather', 'description' => 'Get current weather information' },
              { 'name' => 'get_news', 'description' => 'Fetch latest news headlines' }
            ]
          )
        end

        it 'replies with server configuration and tool information' do
          call_robot
          expected_output = <<~OUTPUT.chomp
            test_server:
              Transport: http
              URL: http://example.com
              Headers: {}
              Tools:
              - get_weather: Get current weather information
              - get_news: Fetch latest news headlines
          OUTPUT
          expect(said_messages).to include(
            a_hash_including(
              body: expected_output
            )
          )
        end
      end

      context 'with tools having long descriptions that need truncation' do
        before do
          long_description = 'A' * 150
          stub_mcp_list_tools(
            base_url: 'http://example.com',
            tools: [{ 'name' => 'long_tool', 'description' => long_description }]
          )
        end

        it 'truncates descriptions longer than 100 characters' do
          call_robot
          expected_description = "#{'A' * 100}..."
          expected_output = <<~OUTPUT.chomp
            test_server:
              Transport: http
              URL: http://example.com
              Headers: {}
              Tools:
              - long_tool: #{expected_description}
          OUTPUT
          expect(said_messages).to include(
            a_hash_including(
              body: expected_output
            )
          )
        end
      end
    end

    context 'with multiple MCP servers' do
      before do
        database = Ruboty::AiAgent::Database.new(robot.brain)
        create_user(database: database, id: 'test_user')
        create_mcp_configuration(database: database, user_id: 'test_user', name: 'server1', url: 'http://example1.com')
        create_mcp_configuration(database: database, user_id: 'test_user', name: 'server2', url: 'http://example2.com')

        stub_mcp_initialize(base_url: 'http://example1.com')
        stub_mcp_initialize(base_url: 'http://example2.com')
        stub_mcp_list_tools(
          base_url: 'http://example1.com',
          tools: [{ 'name' => 'tool1', 'description' => 'Tool 1' }]
        )
        stub_mcp_list_tools(base_url: 'http://example2.com', tools: [])
      end

      it 'displays all servers with double newlines as separators' do
        call_robot
        expected_output = <<~OUTPUT.chomp
          server1:
            Transport: http
            URL: http://example1.com
            Headers: {}
            Tools:
            - tool1: Tool 1

          server2:
            Transport: http
            URL: http://example2.com
            Headers: {}
        OUTPUT
        expect(said_messages).to include(
          a_hash_including(
            body: expected_output
          )
        )
      end
    end
  end
end
