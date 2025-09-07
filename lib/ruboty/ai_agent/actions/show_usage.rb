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
            limit = latest_message_with_usage.token_limit
            message.reply(format_usage_message(usage, limit))
          else
            message.reply('No token usage information found in the conversation history.')
          end
        end

        private

        def format_usage_message(usage, limit = nil)
          message_parts = [
            'Token Usage:',
            "- Prompt tokens: #{usage[:prompt_tokens]}",
            "- Completion tokens: #{usage[:completion_tokens]}",
            "- Total tokens: #{usage[:total_tokens]}"
          ]

          if limit
            usage_percentage = ((usage[:total_tokens].to_f / limit) * 100).round(2)
            message_parts << "- Token limit: #{limit.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
            message_parts << "- Usage: #{usage_percentage}%"
          end

          message_parts.join("\n")
        end
      end
    end
  end
end
