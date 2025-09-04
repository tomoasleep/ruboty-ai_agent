# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # AddAiMemory action for Ruboty::AiAgent
      class AddAiMemory < Base
        def call
          message.reply("TODO: Implement AddAiMemory action with prompt: #{prompt_param}")
        end

        def prompt_param #: String
          message[:prompt]
        end
      end
    end
  end
end
