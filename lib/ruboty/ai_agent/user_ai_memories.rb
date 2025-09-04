# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage Ai Memories for a specific user.
    class UserAiMemories < UserAssociations
      self.association_key = :ai_memories

      # @rbs memory: String
      def add(memory) #: void
        next_id = ((keys.map(&:to_i).max || 0) + 1).to_s
        store(memory, key: next_id)
        next_id
      end
    end
  end
end
