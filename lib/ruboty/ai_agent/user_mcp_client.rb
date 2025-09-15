# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Wrapper for MCP client with caching support for a specific user
    class UserMcpClient
      attr_reader :user #: User
      attr_reader :mcp_name #: String

      # @rbs user: User
      # @rbs mcp_name: String
      # @rbs return: void
      def initialize(user:, mcp_name:)
        @user = user
        @mcp_name = mcp_name
      end

      # @rbs return: Array[tool_def]
      def list_tools
        user.mcp_tools_caches.fetch_or_store_data(mcp_name) do
          mcp_client.list_tools
        end
      end

      # @rbs name: String
      # @rbs arguments: Hash[String, untyped]
      # @rbs &block: ? (Hash[String, untyped]) -> void
      # @rbs return: untyped
      def call_tool(name, arguments = {}, &)
        mcp_client.call_tool(name, arguments, &)
      end

      # @rbs return: untyped
      def list_prompts
        mcp_client.list_prompts
      end

      # @rbs name: String
      # @rbs arguments: Hash[String, untyped]
      # @rbs return: untyped
      def get_prompt(name, arguments = {})
        mcp_client.get_prompt(name, arguments)
      end

      # @rbs return: untyped
      def list_resources
        mcp_client.list_resources
      end

      # @rbs uri: String
      # @rbs return: untyped
      def read_resource(uri)
        mcp_client.read_resource(uri)
      end

      # @rbs return: untyped
      def ping
        mcp_client.ping
      end

      # @rbs return: untyped
      def initialize_session
        mcp_client.initialize_session
      end

      # @rbs return: untyped
      def cleanup_session
        mcp_client.cleanup_session
      end

      # @rbs return: McpConfiguration
      def configuration
        user.mcp_configurations.all_values.find { |config| config.name == mcp_name } ||
          raise("MCP configuration not found: #{mcp_name}")
      end

      private

      # @rbs %a{memorized}
      # @rbs return: HttpMcpClient
      def mcp_client
        @mcp_client ||= case configuration.transport
                        when :http
                          HttpMcpClient.new(
                            url: configuration.url,
                            headers: configuration.headers || {}
                          )
                        else
                          raise "Unknown MCP server type: #{configuration.transport}"
                        end
      end
    end
  end
end
