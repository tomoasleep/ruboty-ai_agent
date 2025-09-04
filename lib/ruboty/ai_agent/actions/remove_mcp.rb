# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveMcp action for Ruboty::AiAgent
      class RemoveMcp < Base
        def call
          if user.mcp_configurations.key?(name_param)
            user.mcp_configurations.remove(name_param)

            message.reply("Removed MCP configuration #{name_param}.")
          else
            message.reply("MCP configuration #{name_param} does not exist.")
          end
        end

        def name_param #: String
          message[:name]
        end
      end
    end
  end
end
