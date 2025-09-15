# frozen_string_literal: true

require 'shellwords'

module Ruboty
  module AiAgent
    module Commands
      # Compact chat history by summarizing it
      class PromptCommand < Base
        attr_reader :definition #: Ruboty::AiAgent::PromptCommandDefinition

        # @rbs definition: Ruboty::AiAgent::PromptCommandDefinition
        # @rbs request: Ruboty::AiAgent::Request
        def initialize(definition:, request:)
          @definition = definition

          super(request:)
        end

        # @rbs commandline: String
        # @rbs return: boolish
        def match?(commandline)
          pattern.match?(commandline)
        end

        def pattern #: Regexp
          %r{\A\s*/#{definition.name}(?:\s+(?<args>.+))?}
        end

        # @rbs commandline: String
        # @rbs return: String
        def call(commandline:)
          result = definition.prompt.dup

          match = pattern.match(commandline) || (raise 'Unreachable')
          args = begin
            Shellwords.split(match[:args] || '')
          rescue ArgumentError
            # If parsing fails, treat the entire string as a single argument
            [match[:args]].compact
          end #: Array[String]

          found = {} #: Hash[Integer, boolish]
          args.each_with_index do |arg, index|
            placeholder = "$#{index + 1}"
            result = result.gsub(placeholder) do
              found[index] = true
              arg
            end
          end

          rest_args = args.each_with_index.reject { |_, index| found[index] }.map(&:first)
          result += "\n\n#{rest_args.join(' ')}" if rest_args.any?

          result
        end
      end
    end
  end
end
