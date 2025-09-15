# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Base class for commands.
      # @abstract
      class Base
        attr_reader :request #: Request

        # @rbs request: Request
        def initialize(request:)
          @request = request

          super()
        end

        def message #: Ruboty::Message
          request.message
        end

        def chat_thread #: Ruboty::AiAgent::ChatThread
          request.chat_thread
        end

        # @rbs *args: untyped
        # @rbs return: untyped
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
