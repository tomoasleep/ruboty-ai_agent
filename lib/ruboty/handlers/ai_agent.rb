# frozen_string_literal: true

require 'ruboty'

module Ruboty
  module Handlers
    # Handler for AI agent commands
    class AiAgent < Base
      env :OPENAI_API_KEY, 'Pass your OpenAI API Key'
      env :OPENAI_MODEL, 'OpenAI model to use', optional: true

      on(
        /(?<body>.+)/m,
        description: 'AI responds to your message if given message did not match any other handlers',
        missing: true,
        name: 'chat'
      )

      on(/add mcp (?<name>\S+)\s+(?<config>.+)\z/, name: 'add_mcp', description: 'Add a new MCP server')
      on(/remove mcp (?<name>\S+)/, name: 'remove_mcp', description: 'Remove the specified MCP server')
      on(/list mcps?/, name: 'list_mcp', description: 'List configured MCP servers')

      on(/set system prompt "(?<prompt>.+)"/, name: 'set_system_prompt', description: 'Set system prompt')
      on(/show system prompt/, name: 'show_system_prompt', description: 'Show system prompt')

      on(/add ai memory "(?<prompt>.+)"/, name: 'add_ai_memory', description: 'Add a new AI memory')
      on(/remove ai memory (?<index>\d+)/, name: 'remove_ai_memory', description: 'Remove the specified AI memory')
      on(/list ai memor(?:y|ies)/, name: 'list_mcp', description: "List AI's memories")

      on(%r{add ai command /(?<name>\S+)\s+"(?<prompt>.+)"}, name: 'add_ai_command',
                                                             description: 'Add a new AI command')
      on(%r{remove ai command /(?<name>\S+)}, name: 'remove_ai_command', description: 'Remove the specified AI command')
      on(/list ai commands?/, name: 'list_mcp', description: 'List AI commands')

      def chat(message)
        Ruboty::AiAgent::Actions::Chat.call(message)
      end

      def add_mcp(message)
        Ruboty::AiAgent::Actions::AddMcp.call(message)
      end

      def remove_mcp(message)
        Ruboty::AiAgent::Actions::RemoveMcp.call(message)
      end

      def list_mcp(message)
        Ruboty::AiAgent::Actions::ListMcp.call(message)
      end

      def set_system_prompt(message)
        Ruboty::AiAgent::Actions::SetSystemPrompt.call(message)
      end

      def show_system_prompt(message)
        Ruboty::AiAgent::Actions::ShowSystemPrompt.call(message)
      end

      def add_ai_memory(message)
        Ruboty::AiAgent::Actions::AddAiMemory.call(message)
      end

      def remove_ai_memory(message)
        Ruboty::AiAgent::Actions::RemoveAiMemory.call(message)
      end

      def list_ai_memories(message)
        Ruboty::AiAgent::Actions::ListAiMemories.call(message)
      end

      def add_ai_command(message)
        Ruboty::AiAgent::Actions::AddAiCommand.call(message)
      end

      def remove_ai_command(message)
        Ruboty::AiAgent::Actions::RemoveAiCommand.call(message)
      end

      def list_ai_commands(message)
        Ruboty::AiAgent::Actions::ListAiCommands.call(message)
      end
    end
  end
end
