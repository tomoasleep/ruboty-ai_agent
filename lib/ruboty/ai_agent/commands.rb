# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Interaction commands (a.k.a. Slash commands, Prompts, etc)
    module Commands
      autoload :Base, 'ruboty/ai_agent/commands/base'
      autoload :Clear, 'ruboty/ai_agent/commands/clear'

      # @rbs message: Ruboty::Message
      # @rbs chat_thread: ChatThread
      # @rbs return: Array[Commands::Base]
      def self.builtins(message:, chat_thread:)
        [
          Commands::Clear.new(
            message:,
            chat_thread:
          )
        ]
      end
    end
  end
end
