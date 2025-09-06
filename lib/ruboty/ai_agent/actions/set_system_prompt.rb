# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # SetSystemPrompt action for Ruboty::AiAgent
      class SetSystemPrompt < Base
        def call
          message.reply("TODO: Implement SetSystemPrompt action with prompt: #{prompt_param}")
        end

        def prompt_param #: String
          message[:prompt]
        end
      end
    end
  end
end
