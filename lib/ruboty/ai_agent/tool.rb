# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Define a tool that the AI agent can use.
    class Tool
      attr_reader :name, :title, :description #: String
      attr_reader :input_schema #: Hash
      attr_reader :on_call #: ? (Hash) -> String

      # @rbs name: String
      # @rbs title: String
      # @rbs description: String
      # @rbs input_schema: Hash?
      # @rbs &on_call: ? (Hash) -> String
      def initialize(name:, title:, description:, input_schema:, &on_call) #: void
        @name = name
        @title = title
        @description = description
        @input_schema = input_schema
        @on_call = on_call
      end

      def call(params) #: String?
        on_call&.call(params)
      end
    end
  end
end
