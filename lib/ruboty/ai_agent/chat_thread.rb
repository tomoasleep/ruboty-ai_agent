# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage thread-specific data.
    class ChatThread
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

      def messages #: ChatThreadMessages
        @messages ||= ChatThreadMessages.new(database: database, chat_thread_id: id)
      end
    end
  end
end
