# frozen_string_literal: true

require 'ruboty/ai_agent/version'
require 'ruboty/handlers/ai_agent'

module Ruboty
  # Add AI Agent feature to Ruboty.
  module AiAgent
    class Error < StandardError; end

    autoload :Actions, 'ruboty/ai_agent/actions'
    autoload :Database, 'ruboty/ai_agent/database'
    autoload :HttpMcpClient, 'ruboty/ai_agent/http_mcp_client'
    autoload :McpConfiguration, 'ruboty/ai_agent/mcp_configuration'
    autoload :Recordable, 'ruboty/ai_agent/recordable'
    autoload :User, 'ruboty/ai_agent/user'
    autoload :UserAiMemories, 'ruboty/ai_agent/user_ai_memories'
    autoload :UserAssociations, 'ruboty/ai_agent/user_associations'
    autoload :UserMcpConfigurations, 'ruboty/ai_agent/user_mcp_configurations'
    autoload :McpClient, 'ruboty/ai_agent/mcp_client'
  end
end
