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
          if chat_thread.messages.empty?
            message.reply('No chat history to compact.')
            return
          end

          summary = chat_thread.messages.summarize(llm: LLM::OpenAI.new)

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
      end
    end
  end
end
