# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manages multiple MCP (Model Context Protocol) clients
    class McpClients
      attr_reader :clients

      # @rbs mcp_configurations: Array[McpConfiguration]
      def initialize(mcp_configurations = [])
        @clients = initialize_mcp_clients(mcp_configurations)
      end

      def available_tools #: Array[Tool]
        clients.flat_map do |client|
          results = client.list_tools
          tool_defs = results.flat_map { |res| res.dig('result', 'tools') || [] }
          tool_defs.map do |tool_def|
            Tool.new(
              name: tool_def['name'],
              title: tool_def['title'] || '',
              description: tool_def['description'] || '',
              input_schema: tool_def['inputSchema']
            ) do |params|
              client.call_tool(tool_def['name'], params)
            end
          end
        end
      end

      def execute_tool(function_name, arguments)
        clients.each do |mcp_client|
          tools = mcp_client.list_tools
          return mcp_client.call_tool(function_name, arguments) if tools.any? { |t| t['name'] == function_name }
        end
      end

      def any?
        @clients.any?
      end

      private

      # @rbs mcp_configurations: Array[McpConfiguration]
      def initialize_mcp_clients(mcp_configurations)
        mcp_configurations.map do |server_config|
          case server_config.transport
          when 'http'
            HttpMcpClient.new(
              url: server_config.url,
              headers: server_config.headers || {}
            )
          else
            raise "Unknown MCP server type: #{server_config.transport}"
          end
        end
      end
    end
  end
end
