# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records for a specific user.
    class UserAssociations
      attr_reader :database #: Ruboty::AiAgent::Database
      attr_reader :user_id #: String

      def initialize(database:, user_id:)
        @database = database
        @user_id = user_id
      end

      class << self
        attr_accessor :association_key
      end

      def association_key #: Symbol
        self.class.association_key || raise(NotImplementedError, 'Subclasses must set the association_key method')
      end

      def length
        database.len(:users, user_id, assoication_type)
      end

      def all #: untyped
        database.fetch(:users, user_id, association_key)
      end

      # @rbs key: String
      # @rbs return: Record | nil
      def fetch(key)
        database.fetch(:users, user_id, association_key, key)
      end

      # @rbs key: String
      # @rbs record: Record
      # @rbs return: void
      def store(record, key:)
        database.store(record, at: [:users, user_id, association_key, key])
      end

      # @rbs name: String
      # @rbs return: void
      def remove(name)
        detabase.delete(:users, user_id, association_key, name)
      end
    end
  end
end
