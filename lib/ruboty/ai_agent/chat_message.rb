# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Save MCP configuration details.
    class ChatMessage
      include Recordable

      register_record_type :chat_message

      attr_reader :role #: Symbol
      attr_reader :content #: String
      attr_reader :tool_call_id #: String?
      attr_reader :tool_name #: String?
      attr_reader :tool_arguments #: Hash?

      # @rbs role: Symbol
      # @rbs content: String
      # @rbs tool_call_id: String?
      # @rbs tool_name: String?
      # @rbs tool_arguments: Hash?
      def initialize(role:, content:, tool_call_id: nil, tool_name: nil, tool_arguments: nil)
        @role = role
        @content = content
        @tool_call_id = tool_call_id
        @tool_name = tool_name
        @tool_arguments = tool_arguments
      end

      def to_h #: Hash
        {
          role:,
          content:,
          tool_call_id:,
          tool_name:,
          tool_arguments:
        }
      end

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
