# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Chat action for Ruboty::AiAgent
      class Chat < Base
        CONVERSATION_KEY = :conversations

        def call
          llm = LLM::OpenAI.new(
            client: OpenAI::Client.new(
              access_token: ENV.fetch('OPENAI_ACCESS_TOKEN', nil),
              log_errors: true
            ),
            model: 'gpt-5-nano'
          )

          thread = database.thread(message.from || 'default')
          thread.messages << ChatMessage.new(
            role: :user,
            content: body_param
          )

          tools = McpClients.new(
            (user.mcp_configurations.all || {}).values
          ).available_tools

          agent = Agent.new(
            llm:,
            messages: thread.messages.all,
            tools:
          )

          agent.complete do |event|
            case event[:type]
            when :new_message
              thread.messages << event[:message]
              message.reply(event[:message].content) if event[:message].content
            when :tool_call
              message.reply("Calling tool #{event[:tool].name} with arguments #{event[:tool_arguments]}",
                            streaming: true)
            when :tool_response
              thread.messages << event[:message]
              message.reply("Tool response: #{event[:tool_response].slice}")
            end
          end
        rescue StandardError => e
          message.reply("エラーが発生しました: #{e.message}")
        end

        def body_param #: String
          message[:body]
        end
      end
    end
  end
end
