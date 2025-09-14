# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveAiCommand action for Ruboty::AiAgent
      class RemoveAiCommand < Base
        def call
          unless user.prompt_command_definitions.key?(name_param)
            message.reply("Command '/#{name_param}' does not exist.")
            return
          end

          user.prompt_command_definitions.remove(name_param)
          message.reply("Command '/#{name_param}' has been removed successfully!")
        end

        def name_param #: String
          message[:name]
        end
      end
    end
  end
end
