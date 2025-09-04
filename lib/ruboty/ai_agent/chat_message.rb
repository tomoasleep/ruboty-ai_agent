# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Save MCP configuration details.
    class ChatMessage < Data.define(:role, :content, :tool_call_id, :tool_name, :tool_arguments)
      include Recordable

      register_record_type :chat_message

      def self.from_llm_response(
        tool:,
        tool_call_id:,
        tool_arguments:,
        tool_response:
      ) #: ChatMessage
        new(
          role: :tool,
          content: tool_response,
          tool_name: tool.name,
          tool_call_id:,
          tool_arguments: tool_arguments
        )
      end
    end
  end
end
