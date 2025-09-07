# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ListAiCommands action for Ruboty::AiAgent
      class ListAiCommands < Base
        # @rbs override
        def call
          commands = Commands.builtins(message:, chat_thread:)

          message.reply(
            commands.flat_map(&:matchers).map { |matcher| "#{matcher.pattern.inspect} - #{matcher.description}" }.join("\n")
          )
        end
      end
    end
  end
end
