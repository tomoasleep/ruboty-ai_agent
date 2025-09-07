# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # SetSystemPrompt action for Ruboty::AiAgent
      class SetSystemPrompt < Base
        def call
          case scope_param.to_sym
          when :user
            user.system_prompt = prompt_param
            message.reply("Set user system prompt: #{prompt_param}")
          when :global
            database.global_settings.system_prompt = prompt_param
            message.reply("Set global system prompt: #{prompt_param}")
          else
            message.reply("Error: Invalid scope '#{scope_param}'. Use 'user' or 'global'.")
          end
        end

        def prompt_param #: String
          message[:prompt]
        end

        def scope_param #: String
          message[:scope] || 'user'
        end
      end
    end
  end
end
