# frozen_string_literal: true

module Ruboty
  module AiAgent
    PromptCommandDefinition = Data.define(
      :name, #: String
      :prompt #: String
    )

    # User-defined command model
    class PromptCommandDefinition
      include Recordable

      register_record_type :user_defined_command
    end
  end
end
