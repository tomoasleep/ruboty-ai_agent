# frozen_string_literal: true

module Ruboty
  module AiAgent
    # User class to manage user-specific data.
    class User
      attr_reader :database #: Ruboty::AiAgent::Database
      attr_reader :id #: String

      class << self
        def find_or_create(database:, id:) #: User
          new(database: database, id: id)
        end
      end

      def initialize(database:, id:)
        @database = database
        @id = id
      end

      def mcp_configurations #: UserMcpConfigurations
        @mcp_configurations ||= UserMcpConfigurations.new(database: database, user_id: id)
      end

      def ai_memories #: UserAiMemories
        @ai_memories ||= UserAiMemories.new(database: database, user_id: id)
      end
    end
  end
end
