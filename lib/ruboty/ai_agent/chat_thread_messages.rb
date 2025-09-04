# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage messages for the chat thread.
    class ChatThreadMessages < ChatThreadAssociations
      self.association_key = :messages

      # @rbs message: ChatMessage
      def add(message) #: void
        store(message, key: (keys.last || -1) + 1)
      end

      alias << add
    end
  end
end
