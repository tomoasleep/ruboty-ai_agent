# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Show token usage information for the latest AI response
      class Usage < BuiltinBase
        on(%r{/usage}, name: 'show_usage', description: 'Show token usage information for the latest AI response')

        def call(*) #: void
          token_usage = chat_thread.messages.token_usage

          if token_usage
            usage_text = "Token usage: #{format_number(token_usage.prompt_tokens)} (prompt) + #{format_number(token_usage.completion_tokens)} (completion) = #{format_number(token_usage.total_tokens)} (total)"

            limit = token_usage.token_limit
            if limit
              usage_percentage = token_usage.usage_percentage
              usage_text += " / #{format_number(limit)} (#{usage_percentage}%)"
            end

            message.reply(usage_text)
          else
            message.reply('No token usage information found.')
          end
        end

        private

        # @rbs number: Integer
        # @rbs return: String
        def format_number(number)
          number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
        end
      end
    end
  end
end
