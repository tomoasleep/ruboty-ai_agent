# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Agent class to interact with LLM and manage conversations.
    class Agent
      attr_reader :llm #: LLM::OpenAI
      attr_reader :messages #: Array[ChatMessage]
      attr_reader :tools #: Array[Tool]

      # @rbs llm: LLM::OpenAI
      # @rbs messages: Array[ChatMessage]
      # @rbs tools: Array[Tool]
      def initialize(
        llm:,
        messages: [],
        tools: []
      )
        @llm = llm
        @messages = messages
        @tools = tools
      end

      def complete(&)
        loop do
          response = llm.complete(
            messages:,
            tools:
          )
          on_response(response, &)
          on_new_message(response.message, &)

          if response.tool
            on_tool_call(tool: response.tool, tool_arguments: response.tool_arguments, &)
            messages << response.message

            tool_response = response.call_tool || 'no return value'
            tool_response_message = ChatMessage.from_llm_response(
              tool: response.tool,
              tool_call_id: response.tool_call_id,
              tool_arguments: response.tool_arguments,
              tool_response:
            )
            on_tool_response(tool_response:, message: tool_response_message, &)
            messages << tool_response_message
          else
            messages << response.message

            return response
          end
        end
      end

      def on_new_message(message, &callback)
        callback&.call({ type: :new_message, message: })
      end

      def on_tool_call(tool:, tool_arguments:, &callback)
        callback&.call({ type: :tool_call, tool:, tool_arguments: })
      end

      def on_tool_response(tool_response:, message:, &callback)
        callback&.call({ type: :tool_response, tool_response:, message: })
      end

      def on_response(response, &callback)
        callback&.call({ type: :response, response: })
      end
    end
  end
end
