# frozen_string_literal: true

module Ruboty
  module AiAgent
    # @rbs!
    #   type tool_def = Hash[Symbol | String, untyped]

    # Manage tools cache for a specific user and server.
    class UserMcpToolsCaches < UserMcpCaches #[Array[tool_def]]
      self.cache_type_key = :tools
      self.cache_duration = ENV.fetch('MCP_CACHE_DURATION', 600).to_i
    end
  end
end
