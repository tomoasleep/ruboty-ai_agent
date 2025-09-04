# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Chat action for Ruboty::AiAgent
      class Chat < Base
        CONVERSATION_KEY = :conversations

        def call
          response = agent.chat(body_param) do |chunk|
            # For streaming support in the future
            # message.reply(chunk, streaming: true) if chunk
          end

          message.reply(response) if response

          # Save conversation history for next time
          save_conversation_history(agent.messages)
        rescue StandardError => e
          message.reply("エラーが発生しました: #{e.message}")
        end

        def body_param #: String
          message[:body]
        end

        private

        def agent
          @agent ||= Agent.new(
            client: openai_client,
            messages: conversation_history,
            system_prompt: user_system_prompt,
            mcp_servers: user_mcp_servers,
            model: user_model || Agent::DEFAULT_MODEL
          )
        end

        def conversation_history
          fetch_conversation_history || []
        end

        def fetch_conversation_history
          database.fetch(:users, user.id, CONVERSATION_KEY)
        rescue StandardError => e
          puts "Failed to fetch conversation history: #{e.message}"
          nil
        end

        def save_conversation_history(messages)
          # Limit conversation history to last 20 messages to avoid token limits
          messages_to_save = messages.last(20)
          database.store(messages_to_save, at: [:users, user.id, CONVERSATION_KEY])
        rescue StandardError => e
          puts "Failed to save conversation history: #{e.message}"
        end

        def user_system_prompt
          database.fetch(:users, user.id, :system_prompt) || default_system_prompt
        rescue StandardError
          default_system_prompt
        end

        def default_system_prompt
          'あなたは親切で有能なアシスタントです。ユーザーの質問に対して、正確で役立つ回答を提供してください。'
        end

        def user_mcp_servers
          mcp_configs = user.mcp_configurations.all
          mcp_configs.map do |config|
            {
              type: config['type'],
              url: config['url'],
              command: config['command'],
              args: config['args'],
              headers: config['headers']
            }.compact
          end
        rescue StandardError => e
          puts "Failed to fetch MCP configurations: #{e.message}"
          []
        end

        def user_model
          database.fetch(:users, user.id, :model)
        rescue StandardError
          nil
        end

        def openai_client
          @openai_client ||= OpenAI::Client.new(
            access_token: ENV.fetch('OPENAI_ACCESS_TOKEN', nil),
            log_errors: true
          )
        end
      end
    end
  end
end
