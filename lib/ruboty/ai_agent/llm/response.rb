# frozen_string_literal: true

module Ruboty
  module AiAgent
    module LLM
      Response = Data.define(
        :message, #: ChatMessage
        :tool, #: Ruboty::AiAgent::Tool?
        :tool_call_id, #: String?
        :tool_arguments #: Hash[String, String]?
      )

      # General response class for LLM interactions.
      class Response
        def call_tool #: String?
          tool&.call(tool_arguments)
        end
      end
    end
  end
end
