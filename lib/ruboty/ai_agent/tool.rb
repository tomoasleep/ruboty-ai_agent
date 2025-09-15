# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Define a tool that the AI agent can use.
    class Tool
      attr_reader :name, :title, :description #: String
      attr_reader :input_schema #: Hash[untyped, untyped]?
      attr_reader :silent #: boolish
      attr_reader :on_call #: (^(Hash[String, untyped]) -> String? )?

      # @rbs name: String
      # @rbs title: String
      # @rbs description: String
      # @rbs input_schema: Hash[untyped, untyped]?
      # @rbs ?silent: boolish?
      # @rbs &on_call: ? (Hash[String, untyped]) -> String?
      def initialize(name:, title:, description:, input_schema:, silent: false, &on_call) #: void
        @name = name
        @title = title
        @description = description
        @input_schema = input_schema
        @silent = silent
        @on_call = on_call
      end

      # Returns true if the tool should be called silently (without notifying the user).
      def silent? #: boolish
        silent
      end

      def call(params) #: String?
        on_call&.call(params)
      end
    end
  end
end
