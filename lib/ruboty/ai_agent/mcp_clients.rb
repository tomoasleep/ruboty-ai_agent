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
            tool_name = "mcp_#{client.mcp_name}__#{tool_def['name']}"
            Tool.new(
              name: tool_name,
              title: tool_def['title'] || '',
              description: tool_def['description'] || '',
              input_schema: tool_def['inputSchema']
            ) do |params|
              client.call_tool(tool_def['name'], params).to_json
            end
          end
        rescue HttpMcpClient::Error => e
          warn "Failed to list tools for MCP client: #{e.message}"
          []
        end
      end

      # @rbs return: bool
      def any?
        @clients.any?
      end
    end
  end
end
