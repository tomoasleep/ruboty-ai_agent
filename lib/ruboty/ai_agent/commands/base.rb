# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Commands
      # Base class for commands.
      # @abstract
      class Base
        attr_reader :message #: Ruboty::Message
        attr_reader :chat_thread #: Ruboty::AiAgent::ChatThread

        # @rbs message: Ruboty::Message
        # @rbs chat_thread: Ruboty::AiAgent::ChatThread
        def initialize(message:, chat_thread:)
          @message = message
          @chat_thread = chat_thread

          super()
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
