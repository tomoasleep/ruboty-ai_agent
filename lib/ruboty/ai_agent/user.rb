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

      # @rbs %a{memorized}
      def mcp_configurations #: UserMcpConfigurations
        @mcp_configurations ||= UserMcpConfigurations.new(database: database, user_id: id)
      end

      def mcp_clients #: Array[UserMcpClient]
        mcp_configurations.all_values.map do |config|
          UserMcpClient.new(user: self, mcp_name: config.name)
        end
      end

      # @rbs %a{memorized}
      def ai_memories #: UserAiMemories
        @ai_memories ||= UserAiMemories.new(database: database, user_id: id)
      end

      def system_prompt #: String?
        database.fetch(:users, id, :system_prompt)
      end

      # @rbs prompt: String?
      def system_prompt=(prompt)
        database.store(prompt, at: [:users, id, :system_prompt])
      end

      # @rbs %a{memorized}
      def mcp_tools_caches #: UserMcpToolsCaches
        @mcp_tools_caches ||= UserMcpToolsCaches.new(database: database, user_id: id)
      end
    end
  end
end
