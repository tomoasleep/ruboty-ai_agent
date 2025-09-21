# frozen_string_literal: true

module Ruboty
  module AiAgent
    module ToolDefinitions
      # Base class for tool definitions
      # @abstract
      class Base
        # @rbs!
        #   type input_schema = Hash[String | Symbol, untyped]

        # @rbs!
        #   def self.tool_name: () -> String?
        #   def self.tool_name=: (String) -> String
        #   def self.tool_title: () -> String?
        #   def self.tool_title=: (String) -> String
        #   def self.tool_description: () -> String?
        #   def self.tool_description=: (String) -> String
        #   def self.tool_input_schema: () -> input_schema?
        #   def self.tool_input_schema=: (input_schema) -> input_schema

        class << self
          def available? #: boolish
            true
          end

          # @rbs skip
          attr_accessor :tool_name

          # @rbs skip
          attr_accessor :tool_title

          # @rbs skip
          attr_accessor :tool_description

          # @rbs skip
          attr_accessor :tool_input_schema
        end

        def tool_name #: String
          self.class.tool_name || (raise NotImplementedError, "Subclasses must define 'tool_name'")
        end

        def tool_title #: String
          self.class.tool_title || ''
        end

        def tool_description #: String
          self.class.tool_description || ''
        end

        def tool_input_schema #: input_schema
          self.class.tool_input_schema || {} #: input_schema
        end

        # Return true if you want the tool not to produce call logs in the chat.
        def silent? #: boolish
          false
        end

        attr_reader :request #: Request

        # @rbs request: Request
        def initialize(request:)
          @request = request
        end

        # @abstract
        # @rbs arguments: Hash[String, untyped]
        # @rbs return: String?
        def call(arguments)
          raise NotImplementedError, "Subclasses must implement the 'call' method"
        end

        def to_tool #: Tool
          Tool.new(
            name: tool_name,
            title: tool_title,
            description: tool_description,
            input_schema: tool_input_schema,
            silent: silent?,
            &method(:call) #: ^ (Hash[String, untyped]) -> String?
          )
        end
      end
    end
  end
end
