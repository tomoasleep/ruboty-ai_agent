# frozen_string_literal: true

module Ruboty
  module AiAgent
    # User-defined commands record set
    class UserPromptCommandDefinitions < UserAssociations #[PromptCommandDefinition]
      self.association_key = :user_prompt_command_definitions

      # @rbs command: PromptCommandDefinition
      # @rbs return: PromptCommandDefinition
      def add(command)
        store(command, key: command.name)
        command
      end
    end
  end
end
