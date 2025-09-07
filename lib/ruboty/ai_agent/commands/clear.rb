# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Clear histories of the chat thread.
      class Clear < Base
        on(%r{/clear}, name: 'clear', description: 'Clear the chat history.')

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
          chat_thread.clear
          message.reply('Cleared the chat history.')
        end
      end
    end
  end
end
