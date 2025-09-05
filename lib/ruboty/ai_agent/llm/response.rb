# frozen_string_literal: true

module Ruboty
  module AiAgent
    module LLM
      # General response class for LLM interactions.
      class Response < Data.define(:message, :tool, :tool_call_id, :tool_arguments)
        def call_tool
          tool&.call(tool_arguments)
        end
      end
    end
  end
end
