# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Save MCP configuration details.
    class McpConfiguration < Data.define(:name, :transport, :headers, :url)
      include Recordable

      register_record_type :mcp_configuration
    end
  end
end
