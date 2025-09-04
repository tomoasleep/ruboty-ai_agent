# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveAiMemory action for Ruboty::AiAgent
      class RemoveAiMemory < Base
        def call
          message.reply("TODO: Implement RemoveAiMemory action for index: #{index_param}")
          if user.ai_memories.key?(index_param)
            user.ai_memories.remove(index_param)

            message.reply("Removed memory #{index_param}.")
          else
            message.reply("Memory #{index_param} does not exist.")
          end
        end

        def index_param #: String
          message[:index]
        end
      end
    end
  end
end
