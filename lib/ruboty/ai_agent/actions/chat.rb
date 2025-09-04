# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # Chat action for Ruboty::AiAgent
      class Chat < Base
        def call
          message.reply("TODO: Implement Chat action with body: #{body_param}")
        end

        def body_param #: String
          message[:body]
        end
      end
    end
  end
end