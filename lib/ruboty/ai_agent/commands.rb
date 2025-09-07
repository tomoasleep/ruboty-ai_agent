# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Interaction commands (a.k.a. Slash commands, Prompts, etc)
    module Commands
      autoload :Base, 'ruboty/ai_agent/commands/base'
      autoload :Clear, 'ruboty/ai_agent/commands/clear'
    end
  end
end
