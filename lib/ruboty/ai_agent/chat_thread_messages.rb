# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage messages for the chat thread.
    class ChatThreadMessages < ChatThreadAssociations #[ChatMessage]
      self.association_key = :messages

      # @rbs message: ChatMessage
      def add(message) #: void
        store(message, key: (keys.last.to_s.to_i || -1) + 1)
      end

      alias << add
    end
  end
end
