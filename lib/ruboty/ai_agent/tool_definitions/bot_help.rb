# frozen_string_literal: true

module Ruboty
  module AiAgent
    module ToolDefinitions
      # Tool for retrieving Ruboty help information
      class BotHelp < Base
        self.tool_name = 'bot_help'
        self.tool_title = 'Show help information about this bot (you)'

        self.tool_description = <<~TEXT
          Get help information about available patterns of this bot (you).
          This returns the same information as the 'help' command in Ruboty.

          # Hint

          - You are a Ruboty bot. You can find available commands by using this tool.
          - If user asks for what you can do or usage (e.g. "Tell me the usage", "How do I use it?"), use this tool to respond.
          - If user asks for specific commands, use the 'filter' argument to search for them.
          - If user typed a command that you don't know, use this tool to find out the correct command.
        TEXT

        self.tool_input_schema = {
          type: 'object',
          properties: {
            filter: {
              type: 'string',
              description: 'Optional filter to search for specific commands (e.g., "mcp", "ai", "ping")'
            }
          },
          required: []
        }

        # @rbs arguments: Hash[String, untyped]
        # @rbs return: String?
        def call(arguments)
          filter = arguments['filter']

          descriptions = filtered_descriptions(filter)

          if descriptions.empty?
            if filter
              "No description matched to '#{filter}'"
            else
              'No commands available'
            end
          else
            descriptions.join("\n")
          end
        end

        private

        # @rbs filter: String?
        # @rbs return: Array[String]
        def filtered_descriptions(filter)
          descriptions = all_descriptions

          if filter
            descriptions.select! do |description|
              description.include?(filter)
            end
          end

          descriptions
        end

        # @rbs return: Array[String]
        def all_descriptions
          actions = Ruboty.actions.reject(&:hidden?)

          # Sort by description for consistent ordering
          sorted_actions = begin
            actions.sort_by(&:description)
          rescue ArgumentError
            # Fallback if sorting fails (e.g., in tests with mocks)
            actions
          end

          sorted_actions.map do |action|
            prefix = ''
            prefix += "#{request.message.robot.name} " unless action.all?
            "#{prefix}#{action.pattern.inspect} - #{action.description}"
          end
        end
      end
    end
  end
end
