# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Compact chat history by summarizing it
      class Compact < Base
        on(%r{/compact}, name: 'compact', description: 'Compact the chat history by summarizing it.')

        attr_reader :message #: Ruboty::Message
        attr_reader :chat_thread #: Ruboty::AiAgent::ChatThread

        # @rbs message: Ruboty::Message
        # @rbs chat_thread: Ruboty::AiAgent::ChatThread
        def initialize(message:, chat_thread:)
          @message = message
          @chat_thread = chat_thread

          super()
        end

        def call #: void
          messages = chat_thread.messages.all_values

          if messages.empty?
            message.reply('No chat history to compact.')
            return
          end

          summary = generate_summary(messages)

          chat_thread.clear
          chat_thread.messages.add(
            ChatMessage.new(
              role: :system,
              content: "Previous conversation summary: #{summary}"
            )
          )

          message.reply('Chat history has been compacted with a summary.')
        rescue StandardError => e
          if ENV['DEBUG']
            message.reply("エラーが発生しました: #{e.full_message}")
          else
            message.reply("エラーが発生しました: #{e.message}")
          end
        end

        private

        # @rbs messages: Array[ChatMessage]
        # @rbs return: String
        def generate_summary(messages)
          llm = LLM::OpenAI.new(
            client: OpenAI::Client.new(
              api_key: ENV.fetch('OPENAI_API_KEY', nil)
            ),
            model: ENV.fetch('OPENAI_MODEL', 'gpt-5-nano')
          )

          summary_prompt = ChatMessage.new(
            role: :system,
            content: <<~TEXT
              Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:
            TEXT
          )

          response = llm.complete(messages: [summary_prompt, *messages])
          response.message.content
        end

        # @rbs messages: Array[ChatMessage]
        # @rbs return: String
        def format_messages_for_summary(messages)
          messages.map do |msg|
            "#{msg.role}: #{msg.content}"
          end.join("\n")
        end
      end
    end
  end
end
