# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # AddAiCommand action for Ruboty::AiAgent
      class AddAiCommand < Base
        def call
          message.reply("TODO: Implement AddAiCommand action - name: #{name_param}, prompt: #{prompt_param}")
        end

        def name_param #: String
          message[:name]
        end

        def prompt_param #: String
          message[:prompt]
        end
      end
    end
  end
end
