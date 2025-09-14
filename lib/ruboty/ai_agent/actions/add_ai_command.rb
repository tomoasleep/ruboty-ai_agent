# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # AddAiCommand action for Ruboty::AiAgent
      class AddAiCommand < Base
        def call
          if user.prompt_command_definitions.key?(name_param)
            message.reply("Command '/#{name_param}' already exists. Use a different name or remove the existing command first.")
            return
          end

          new_command = PromptCommandDefinition.new(name: name_param, prompt: undump_string(prompt_param))
          user.prompt_command_definitions.add(new_command)
          message.reply("Command '/#{name_param}' has been added successfully!")
        end

        def name_param #: String
          message[:name]
        end

        def prompt_param #: String
          message[:prompt]
        end

        # @rbs str: String
        # @rbs return: String
        def undump_string(str)
          str.undump
        rescue StandardError
          str
        end
      end
    end
  end
end
