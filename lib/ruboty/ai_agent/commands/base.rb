# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Base class for commands.
      # @abstract
      class Base
        Matcher = Data.define(:pattern, :description, :name)

        class << self
          def matchers #: Array[Matcher]
            @matchers ||= []
          end

          def on(pattern, name:, description:)
            matchers << Matcher.new(pattern:, description:, name:)
          end
        end

        # @rbs *args: untyped
        # @rbs return: void
        def call(*args)
          raise NotImplementedError
        end

        # @rbs commandline: String
        # @rbs return: boolish
        def match?(commandline)
          matchers.any? { |matcher| /\A\s*#{matcher.pattern}/.match?(commandline) }
        end

        def matchers #: Array[Matcher]
          self.class.matchers
        end
      end
    end
  end
end
