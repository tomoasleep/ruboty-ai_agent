# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Base class for actions.
      # @abstract
      class Base
        attr_reader :message #: Ruboty::Message

        # @rbs message: Ruboty::Message
        # @rbs return: void
        def self.call(message)
          new(message).call
        end

        # @rbs return: void
        def call
          raise NotImplementedError
        end

        def initialize(message)
          @message = message
        end

        # @rbs %a{memorized}
        def database #: Ruboty::AiAgent::Database
          @database ||= Ruboty::AiAgent::Database.new(message.robot.brain)
        end

        def user #: Ruboty::AiAgent::User
          database.user(message.from_name)
        end
      end
    end
  end
end
