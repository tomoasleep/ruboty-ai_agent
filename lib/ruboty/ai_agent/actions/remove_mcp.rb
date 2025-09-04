# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # RemoveMcp action for Ruboty::AiAgent
      class RemoveMcp < Base
        def call
          message.reply("TODO: Implement RemoveMcp action for #{name_param}")
        end

        def name_param #: String
          message[:name]
        end
      end
    end
  end
end