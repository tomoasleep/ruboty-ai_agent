# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Tool Definitions for AI Agent
    module ToolDefinitions
      autoload :Base, 'ruboty/ai_agent/tool_definitions/base'
      autoload :Think, 'ruboty/ai_agent/tool_definitions/think'

      # @rbs request: Request
      # @rbs return: Array[Base]
      def self.builtins(request:)
        [
          Think
        ].map { |tool_def| tool_def.new(request:) }
      end
    end
  end
end
