# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manages multiple MCP (Model Context Protocol) clients
    class McpClients
      attr_reader :clients #: Array[UserMcpClient]

      # @rbs clients: Array[UserMcpClient]
      def initialize(clients)
        @clients = clients
      end

      # @rbs return: Array[Tool]
      def available_tools
        clients.flat_map do |client|
          tool_defs = client.list_tools
          tool_defs.map do |tool_def|
            Tool.new(
              name: tool_def['name'],
              title: tool_def['title'] || '',
              description: tool_def['description'] || '',
              input_schema: tool_def['inputSchema']
            ) do |params|
              client.call_tool(tool_def['name'], params).to_json
            end
          end
        end
      end

      # @rbs function_name: String
      # @rbs arguments: Hash[String, untyped]
      # @rbs return: untyped
      def execute_tool(function_name, arguments)
        clients.each do |mcp_client|
          tools = mcp_client.list_tools
          return mcp_client.call_tool(function_name, arguments) if tools.any? { |t| t['name'] == function_name }
        end
        nil
      end

      # @rbs return: bool
      def any?
        @clients.any?
      end
    end
  end
end
