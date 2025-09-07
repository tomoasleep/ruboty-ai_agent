# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Clear histories of the chat thread.
      class Clear < Base
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

        # @rbs override
        def match?(commandline)
          commandline.match(%r{\A\s*(/clear)})
        end
      end
    end
  end
end
