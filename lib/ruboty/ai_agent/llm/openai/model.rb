# frozen_string_literal: true

module Ruboty
  module AiAgent
    module LLM
      class OpenAI
        # Model information and token limit estimation
        class Model
          attr_reader :name #: String

          # @rbs name: String
          def initialize(name)
            @name = name
          end

          # Estimate token limit based on model name
          # @rbs return: Integer
          def token_limit
            if name.include?('gpt-5')
              400_000
            else
              128_000
            end
          end
        end
      end
    end
  end
end
