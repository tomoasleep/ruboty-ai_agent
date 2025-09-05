# frozen_string_literal: true

require 'json'

require 'ruboty/ai_agent/version'
require 'ruboty/handlers/ai_agent'

module Ruboty
  # Add AI Agent feature to Ruboty.
  module AiAgent
    class Error < StandardError; end

    autoload :Actions, 'ruboty/ai_agent/actions'
    autoload :Agent, 'ruboty/ai_agent/agent'
    autoload :ChatMessage, 'ruboty/ai_agent/chat_message'
    autoload :ChatThread, 'ruboty/ai_agent/chat_thread'
    autoload :ChatThreadAssociations, 'ruboty/ai_agent/chat_thread_associations'
    autoload :ChatThreadMessages, 'ruboty/ai_agent/chat_thread_messages'
    autoload :Database, 'ruboty/ai_agent/database'
    autoload :HttpMcpClient, 'ruboty/ai_agent/http_mcp_client'
    autoload :LLM, 'ruboty/ai_agent/llm'
    autoload :McpClient, 'ruboty/ai_agent/mcp_client'
    autoload :McpClients, 'ruboty/ai_agent/mcp_clients'
    autoload :McpConfiguration, 'ruboty/ai_agent/mcp_configuration'
    autoload :Recordable, 'ruboty/ai_agent/recordable'
    autoload :RecordSet, 'ruboty/ai_agent/record_set'
    autoload :Tool, 'ruboty/ai_agent/tool'
    autoload :User, 'ruboty/ai_agent/user'
    autoload :UserAiMemories, 'ruboty/ai_agent/user_ai_memories'
    autoload :UserAssociations, 'ruboty/ai_agent/user_associations'
    autoload :UserMcpConfigurations, 'ruboty/ai_agent/user_mcp_configurations'
  end
end
