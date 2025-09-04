# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage Ai Memories for a specific user.
    class UserAiMemories < UserAssociations
      self.association_key = :ai_memories

      # @rbs memory: String
      def add(memory) #: void
        store(memory, key: length)
      end
    end
  end
end
