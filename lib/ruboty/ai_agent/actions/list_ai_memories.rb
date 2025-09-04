# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ListAiMemories action for Ruboty::AiAgent
      class ListAiMemories < Base
        def call
          memories = (user.ai_memories.all || {}).map do |idx, memory|
            "Memory #{idx}: #{memory}"
          end.join("\n")

          message.reply(memories.empty? ? 'No memories found.' : memories)
        end
      end
    end
  end
end
