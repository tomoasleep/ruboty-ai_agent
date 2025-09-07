# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage Ai Memories for a specific user.
    class UserAiMemories < UserAssociations #[String]
      self.association_key = :ai_memories

      # @rbs memory: String
      def add(memory) #: void
        next_id = ((keys.map { |key| Integer(key) }.max || 0) + 1).to_s # steep:ignore
        store(memory, key: next_id)
        next_id
      end
    end
  end
end
