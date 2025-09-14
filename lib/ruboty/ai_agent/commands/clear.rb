# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Clear histories of the chat thread.
      class Clear < BuiltinBase
        on(%r{/clear}, name: 'clear', description: 'Clear the chat history.')

        def call(*) #: void
          chat_thread.clear
          message.reply('Cleared the chat history.')
        end
      end
    end
  end
end
