# frozen_string_literal: true

require 'openai'

module Ruboty
  module AiAgent
    module LLM
      # LLM interface for OpenAI's chat completion API.
      class OpenAI
        attr_reader :client #: OpenAI::Client
        attr_reader :model #: String

        # @rbs client: OpenAI::Client
        # @rbs model: String
        def initialize(client:, model:)
          @client = client
          @model = model
        end

        # @rbs messages: Array[ChatMessage]
        # @rbs tools: Array[Tool]
        # @rbs return: Response
        def complete(messages:, tools: [])
          openai_response = client.chat.completions.create(
            model:,
            messages: openai_messages_from_messages(messages),
            tools: openai_tools_from_tools(tools)
          )

          to_response(openai_response:, tools:)
        end

        private

        # @rbs messages: Array[ChatMessage]
        # @rbs return: Array[Hash]
        def openai_messages_from_messages(messages)
          messages.map do |message|
            case message.role.to_sym
            when :system
              { role: 'system', content: message.content }
            when :user
              { role: 'user', content: message.content }
            when :assistant
              tool_calls = if message.tool_call_id
                             [
                               {
                                 id: message.tool_call_id,
                                 function: {
                                   name: message.tool_name,
                                   arguments: message.tool_arguments.to_json
                                 }
                               }
                             ]
                           else
                             []
                           end

              {
                role: 'assistant',
                content: message.content,
                tool_calls: tool_calls
              }
            when :tool
              { role: 'tool', name: message.name, tool_call_id: message.tool_call_id, content: message.content }
            else
              raise "Unknown message role: #{message.role}"
            end
          end
        end

        # @rbs tools: Array[Tool]
        # @rbs return: Array[Hash]
        def openai_tools_from_tools(tools)
          tools.map do |tool|
            {
              type: 'function',
              function: {
                name: tool.name,
                description: tool.description,
                parameters: tool.inputSchema || {
                  type: 'object',
                  properties: {},
                  required: []
                }
              }
            }
          end
        end

        # @rbs openai_response: OpenAI::ChatCompletion
        # @rbs tools: Array[Tool]
        # @rbs return: Response
        def to_response(openai_response:, tools:)
          choice = openai_response.choices.first
          tool_call = choice.message.tool_calls&.first

          tool = tools.find { |t| t.name == tool_call.function.name } if tool_call

          Response.new(
            message: ChatMessage.new(
              role: choice.message.role,
              content: choice.message.content,
              tool_call_id: tool_call&.id,
              tool_name: tool&.name,
              tool_arguments: tool_call ? JSON.parse(tool_call.function.arguments, { symbolize_names: true }) : nil
            ),
            tool:,
            tool_call_id: tool_call&.id,
            tool_arguments: tool_call ? JSON.parse(tool_call.function.arguments, { symbolize_names: true }) : nil
          )
        end
      end
    end
  end
end
