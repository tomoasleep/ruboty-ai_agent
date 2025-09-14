# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Chat action for Ruboty::AiAgent
      class Chat < Base
        CONVERSATION_KEY = :conversations

        # @rbs override
        def call
          user.prompt_command_definitions.all_values.each do |definition|
            command = Commands::PromptCommand.new(definition:, message:, chat_thread:)
            if command.match?(body_param)
              new_prompt = command.call(commandline: body_param)
              return complete_chat(new_prompt)
            end
          end

          builtin_commands = Commands.builtins(message:, chat_thread:)
          builtin_commands.each do |command|
            return command.call if command.match?(body_param)
          end

          complete_chat(body_param)
        end

        def body_param #: String
          message[:body]
        end

        private

        # @rbs body: String
        # @rbs return: void
        def complete_chat(body)
          chat_thread.messages << ChatMessage.new(
            role: :user,
            content: body
          )

          messages = [] #: Array[ChatMessage]

          global_prompt = database.global_settings.system_prompt
          messages << ChatMessage.new(role: :system, content: global_prompt) if global_prompt

          user_prompt = user.system_prompt
          messages << ChatMessage.new(role: :system, content: user_prompt) if user_prompt

          messages += chat_thread.messages.all_values

          llm = LLM::OpenAI.new
          tools = McpClients.new(user.mcp_clients).available_tools

          agent = Agent.new(
            llm:,
            messages:,
            tools:
          )

          agent.complete do |event|
            case event[:type]
            when :new_message
              chat_thread.messages << event[:message]
              message.reply(event[:message].content) if event[:message].content.length.positive?

              chat_thread.messages.compact(llm:) if chat_thread.messages.over_auto_compact_threshold?
            when :tool_call
              message.reply("Calling tool #{event[:tool].name} with arguments #{event[:tool_arguments]}",
                            streaming: true)
            when :tool_response
              chat_thread.messages << event[:message]
              message.reply("Tool response: #{event[:tool_response].slice(0..100)}")
            end
          end
        rescue StandardError => e
          if ENV['DEBUG']
            message.reply("エラーが発生しました: #{e.full_message}")
          else
            message.reply("エラーが発生しました: #{e.message}")
          end
        end
      end
    end
  end
end
