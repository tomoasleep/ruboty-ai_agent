# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ListAiCommands action for Ruboty::AiAgent
      class ListAiCommands < Base
        # @rbs override
        def call
          builtin_commands = Commands.builtins(request: Request.new(message:, chat_thread:))

          builtin_list = builtin_commands.flat_map(&:matchers)
                                         .map { |matcher| "#{matcher.pattern.inspect} - #{matcher.description}" }

          user_defined_list = user.prompt_command_definitions.all_values
                                  .map { |cmd| "/#{cmd.name} - #{cmd.prompt}" }

          content = <<~TEXT
            # User-Defined Commands
            #{user_defined_list.empty? ? 'No user-defined commands available.' : user_defined_list.join("\n")}

            # Built-in Commands
            #{builtin_list.empty? ? 'No built-in commands available.' : builtin_list.join("\n")}
          TEXT

          if builtin_commands.empty? && user_defined_list.empty?
            message.reply('No commands available.')
          else
            message.reply(content)
          end
        end
      end
    end
  end
end
