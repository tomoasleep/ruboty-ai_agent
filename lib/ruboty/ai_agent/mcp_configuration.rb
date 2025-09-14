# frozen_string_literal: true

module Ruboty
  module AiAgent
    # @rbs!
    #   type transports = :http | :websocket
    #   type transports_str = "http" | "websocket"

    McpConfiguration = Data.define(
      :name, #: String
      :transport, #: transports
      :headers, #: Hash[String, String]
      :url #: String
    )

    # Save MCP configuration details.
    class McpConfiguration
      include Recordable

      # @rbs name: String
      # @rbs transport: transports | transports_str
      # @rbs url: String
      # @rbs headers: Hash[String, String]?
      def initialize(name:, transport:, url:, headers: {})
        # No superclass method `initialize` in RBS.
        super(name:, transport: transport.to_sym, headers:, url:) # steep:ignore UnexpectedKeywordArgument
      end

      register_record_type :mcp_configuration
    end
  end
end
