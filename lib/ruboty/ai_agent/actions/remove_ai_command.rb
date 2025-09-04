# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveAiCommand action for Ruboty::AiAgent
      class RemoveAiCommand < Base
        def call
          message.reply("TODO: Implement RemoveAiCommand action for name: #{name_param}")
        end

        def name_param #: String
          message[:name]
        end
      end
    end
  end
end