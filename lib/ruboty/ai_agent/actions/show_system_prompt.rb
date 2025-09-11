# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ShowSystemPrompt action for Ruboty::AiAgent
      class ShowSystemPrompt < Base
        def call
          user_prompt = user.system_prompt
          global_prompt = database.global_settings.system_prompt

          reply = [] #: Array[String]
          reply << if user_prompt
                     "User system prompt: #{user_prompt}"
                   else
                     'User system prompt is not set.'
                   end

          reply << if global_prompt
                     "Global system prompt: #{global_prompt}"
                   else
                     'Global system prompt is not set.'
                   end

          message.reply(reply.join("\n"))
        end
      end
    end
  end
end
