# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Show latest token usage information for AI responses
      class ShowUsage < Base
        def call
          latest_message_with_usage = chat_thread.messages.all_values.reverse.find(&:token_usage)

          if latest_message_with_usage
            usage = latest_message_with_usage.token_usage
            message.reply(format_usage_message(usage))
          else
            message.reply('No token usage information found in the conversation history.')
          end
        end

        private

        def format_usage_message(usage)
          <<~MESSAGE
            Token Usage:
            - Prompt tokens: #{usage[:prompt_tokens]}
            - Completion tokens: #{usage[:completion_tokens]}
            - Total tokens: #{usage[:total_tokens]}
          MESSAGE
        end
      end
    end
  end
end
