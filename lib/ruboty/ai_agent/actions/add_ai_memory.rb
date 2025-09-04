# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # AddAiMemory action for Ruboty::AiAgent
      class AddAiMemory < Base
        def call
          idx = user.ai_memories.add(prompt_param)

          message.reply("Added memory #{idx}: #{prompt_param}")
        end

        def prompt_param #: String
          message[:prompt]
        end
      end
    end
  end
end
