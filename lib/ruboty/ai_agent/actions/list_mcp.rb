# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ListMcp action for Ruboty::AiAgent
      class ListMcp < Base
        def call
          mcp_configurations = (user.mcp_configurations.all || {}).map do |name, mcp_configuration|
            "#{name}: #{mcp_configuration.to_h.except(:record_type).to_json}"
          end.join("\n")

          message.reply(mcp_configurations.empty? ? 'No memories found.' : mcp_configurations)
        end
      end
    end
  end
end
