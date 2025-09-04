# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveAiMemory action for Ruboty::AiAgent
      class RemoveAiMemory < Base
        def call
          message.reply("TODO: Implement RemoveAiMemory action for index: #{index_param}")
        end

        def index_param #: String
          message[:index]
        end
      end
    end
  end
end