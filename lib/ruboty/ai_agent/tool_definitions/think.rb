# frozen_string_literal: true

module Ruboty
  module AiAgent
    module ToolDefinitions
      # Tool
      class Think < Base
        self.tool_name = 'think'
        self.tool_title = 'Think'

        self.tool_description = <<~TEXT
          Use this tool to think abount something. It will not obtain new information or make any changes, but just log the thought.
          Use it when completx reasoing or brainstorming is needed.
        TEXT

        self.tool_input_schema = {
          type: 'object',
          properties: {
            thought: { type: 'string', description: 'Your thought.' }
          },
          required: ['thought']
        }

        # @rbs arguments: Hash[String, untyped]
        # @rbs return: String?
        def call(arguments)
          thought = arguments['thought']

          request.message.reply("Thought:\n#{thought}")

          thought
        end

        # @rbs override
        def silent?
          true
        end
      end
    end
  end
end
