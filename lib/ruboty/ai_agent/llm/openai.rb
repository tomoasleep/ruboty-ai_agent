# frozen_string_literal: true

require 'openai'

module Ruboty
  module AiAgent
    module LLM
      # LLM interface for OpenAI's chat completion API.
      class OpenAI
        autoload :Model, 'ruboty/ai_agent/llm/openai/model'
        attr_reader :client #: OpenAI::Client
        attr_reader :model #: String

        # @rbs ?client: OpenAI::Client
        # @rbs ?model: String
        def initialize(client: nil, model: nil)
          @client = client || ::OpenAI::Client.new(api_key: ENV.fetch('OPENAI_API_KEY', nil))
          @model = model || ENV.fetch('OPENAI_MODEL', 'gpt-5-nano')
        end

        # @rbs %a{memorized}
        def model_info #: Model
          @model_info ||= Model.new(model)
        end

        # @rbs messages: Array[ChatMessage]
        # @rbs tools: Array[Tool]
        # @rbs return: Response
        def complete(messages:, tools: [])
          openai_response = client.chat.completions.create(
            model:,
            messages: openai_messages_from_messages(messages), #: untyped
            tools: openai_tools_from_tools(tools)
          )

          to_response(openai_response:, tools:)
        end

        private

        # @rbs!
        #   type tool_call = {
        #     id: String,
        #     type: 'function',
        #     function: { name: String, arguments: String }
        #   }

        # @rbs!
        #   type system_message = { role: 'system', content: String }
        #   type user_message = { role: 'user', content: String }
        #   type assistant_message = { role: 'assistant', content: String, tool_calls: Array[tool_call]? }
        #   type tool_message = { role: 'tool', tool_call_id: String, content: String }
        #   type message = system_message | user_message | assistant_message | tool_message

        # @rbs messages: Array[ChatMessage]
        # @rbs return: Array[OpenAI::Models::Chat::chat_completion_message_param]
        def openai_messages_from_messages(messages)
          messages.map do |message|
            case message.role.to_sym
            when :system
              ::OpenAI::Models::Chat::ChatCompletionSystemMessageParam.new(
                role: :system, content: message.content
              )
            when :user
              ::OpenAI::Models::Chat::ChatCompletionUserMessageParam.new(
                role: :user, content: message.content
              )
              # { role: 'user', content: message.content } #: user_message
            when :assistant
              if message.tool_call_id
                tool_calls = [
                  ::OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall.new(
                    id: message.tool_call_id,
                    type: :function,
                    function: ::OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall::Function.new(
                      name: message.tool_name || 'unknown_tool',
                      arguments: message.tool_arguments.to_json
                    )
                  )
                ]
              end

              if tool_calls
                ::OpenAI::Models::Chat::ChatCompletionAssistantMessageParam.new(
                  role: :assistant,
                  content: message.content,
                  tool_calls: tool_calls
                )
              else
                ::OpenAI::Models::Chat::ChatCompletionAssistantMessageParam.new(
                  role: :assistant,
                  content: message.content
                )
              end
            when :tool
              ::OpenAI::Models::Chat::ChatCompletionToolMessageParam.new(
                role: :tool,
                tool_call_id: message.tool_call_id || 'unknown_tool_call_id',
                content: message.content
              )
            else
              raise "Unknown message role: #{message.role}"
            end
          end
        end

        # @rbs tools: Array[Tool]
        # @rbs return: Array[OpenAI::Models::Chat::chat_completion_tool]
        def openai_tools_from_tools(tools)
          tools.map do |tool|
            ::OpenAI::Models::Chat::ChatCompletionFunctionTool.new(
              type: :function,
              function: ::OpenAI::FunctionDefinition.new(
                name: tool.name,
                description: tool.description,
                parameters: tool.input_schema || {
                  type: 'object',
                  properties: {}, #: Hash[untyped, untyped]
                  required: [] #: Array[untyped]
                }
              )
            )
          end
        end

        # @rbs openai_response: OpenAI::Models::Chat::ChatCompletion
        # @rbs tools: Array[Tool]
        # @rbs return: Response
        def to_response(openai_response:, tools:)
          choice = openai_response.choices.first
          tool_call = choice.message.tool_calls&.first

          token_usage = if openai_response.usage
                          TokenUsage.new(
                            prompt_tokens: openai_response.usage.prompt_tokens,
                            completion_tokens: openai_response.usage.completion_tokens,
                            total_tokens: openai_response.usage.total_tokens,
                            token_limit: model_info.token_limit
                          )
                        end

          if tool_call
            tool = tools.find do |t|
              if tool_call.type == :function
                function_name =
                  tool_call #: OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall
                  .function.name
                t.name == function_name
              else
                false
              end
            end
          end

          tool_arguments =
            if tool_call && tool_call.type == :function
              arguments =
                tool_call #: OpenAI::Models::Chat::ChatCompletionMessageFunctionToolCall
                .function.arguments

              JSON.parse(arguments)
            end

          Response.new(
            message: ChatMessage.new(
              role: choice.message.role,
              content: choice.message.content || '',
              tool_call_id: tool_call&.id,
              tool_name: tool&.name,
              tool_arguments:,
              token_usage:
            ),
            tool:,
            tool_call_id: tool_call&.id,
            tool_arguments:
          )
        end
      end
    end
  end
end
