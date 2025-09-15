# frozen_string_literal: true

module Ruboty
  module AiAgent
    Request = Data.define(
      :message, #: Ruboty::Message
      :chat_thread #: Ruboty::AiAgent::ChatThread
    )

    # Request for chat action from user.
    class Request
      def message_body #: String
        message[:body]
      end
    end
  end
end
