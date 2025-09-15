# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Interaction commands (a.k.a. Slash commands, Prompts, etc)
    module Commands
      autoload :Base, 'ruboty/ai_agent/commands/base'
      autoload :BuiltinBase, 'ruboty/ai_agent/commands/builtin_base'
      autoload :Clear, 'ruboty/ai_agent/commands/clear'
      autoload :Compact, 'ruboty/ai_agent/commands/compact'
      autoload :Usage, 'ruboty/ai_agent/commands/usage'
      autoload :PromptCommand, 'ruboty/ai_agent/commands/prompt_command'

      # @rbs request: Request
      # @rbs return: Array[Commands::BuiltinBase]
      def self.builtins(request:)
        [
          Commands::Clear,
          Commands::Compact,
          Commands::Usage
        ].map { |cmd_class| cmd_class.new(request: request) }
      end
    end
  end
end
