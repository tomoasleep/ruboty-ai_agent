# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Base class for commands.
      # @abstract
      class Base
        # @rbs *args: untyped
        # @rbs return: void
        def call(*args)
          raise NotImplementedError
        end

        # @rbs commandline: String
        # @rbs return: boolish
        # @abstract
        def match?(commandline)
          raise NotImplementedError
        end
      end
    end
  end
end
