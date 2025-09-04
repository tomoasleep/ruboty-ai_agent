# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Ruboty AI Agent actions.
    module Actions
      autoload :AddAiCommand, 'ruboty/ai_agent/actions/add_ai_command'
      autoload :AddAiMemory, 'ruboty/ai_agent/actions/add_ai_memory'
      autoload :AddMcp, 'ruboty/ai_agent/actions/add_mcp'
      autoload :Base, 'ruboty/ai_agent/actions/base'
      autoload :Chat, 'ruboty/ai_agent/actions/chat'
      autoload :ListAiCommands, 'ruboty/ai_agent/actions/list_ai_commands'
      autoload :ListAiMemories, 'ruboty/ai_agent/actions/list_ai_memories'
      autoload :ListMcp, 'ruboty/ai_agent/actions/list_mcp'
      autoload :RemoveAiCommand, 'ruboty/ai_agent/actions/remove_ai_command'
      autoload :RemoveAiMemory, 'ruboty/ai_agent/actions/remove_ai_memory'
      autoload :RemoveMcp, 'ruboty/ai_agent/actions/remove_mcp'
      autoload :SetSystemPrompt, 'ruboty/ai_agent/actions/set_system_prompt'
      autoload :ShowSystemPrompt, 'ruboty/ai_agent/actions/show_system_prompt'
    end
  end
end
