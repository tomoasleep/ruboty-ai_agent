# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Token usage information from LLM responses
    class TokenUsage
      include Recordable

      register_record_type :token_usage

      attr_reader :prompt_tokens #: Integer
      attr_reader :completion_tokens #: Integer
      attr_reader :total_tokens #: Integer
      attr_reader :token_limit #: Integer?

      # @rbs prompt_tokens: Integer
      # @rbs completion_tokens: Integer
      # @rbs total_tokens: Integer
      # @rbs ?token_limit: Integer?
      def initialize(prompt_tokens:, completion_tokens:, total_tokens:, token_limit: nil)
        @prompt_tokens = prompt_tokens
        @completion_tokens = completion_tokens
        @total_tokens = total_tokens
        @token_limit = token_limit
      end

      # Calculate usage percentage if token limit is available
      # @rbs return: (Float | nil)
      def usage_percentage
        return nil unless token_limit

        (total_tokens.to_f / token_limit * 100).round(2).to_f
      end

      # Check if usage percentage exceeds auto compact threshold
      # @rbs return: bool
      def over_auto_compact_threshold?
        percentage = usage_percentage
        return false unless percentage

        threshold = ENV.fetch('AUTO_COMPACT_THRESHOLD', 80).to_f
        percentage >= threshold
      end

      def to_h #: Hash[Symbol, untyped]
        {
          prompt_tokens:,
          completion_tokens:,
          total_tokens:,
          token_limit:
        }
      end
    end
  end
end
