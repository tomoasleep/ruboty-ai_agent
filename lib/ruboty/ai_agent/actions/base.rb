# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Base class for actions.
      # @abstract
      class Base
        # @rbs message: Ruboty::Message
        # @rbs return: void
        def self.call(message)
          new(message).call
        end
      end
    end
  end
end
