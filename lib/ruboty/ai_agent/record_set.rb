# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records.
    class RecordSet
      attr_reader :database #: Ruboty::AiAgent::Database

      def initialize(database:)
        @database = database
      end

      def namespace_keys #: Array[Symbol | String]
        raise NotImplementedError, 'Subclasses must implement the namespace_keys method'
      end

      def length #: Integer
        database.len(*namespace_keys)
      end

      def all #: untyped
        database.fetch(*namespace_keys)
      end

      # @rbs key: String
      # @rbs return: Record | nil
      def fetch(key)
        database.fetch(*namespace_keys, key)
      end

      # @rbs key: String
      # @rbs record: Record
      # @rbs return: void
      def store(record, key:)
        database.store(record, at: [*namespace_keys, key])
      end

      # @rbs key: String
      # @rbs return: void
      def remove(key)
        detabase.delete(*namespace_keys, key)
      end

      def key?(key)
        database.key?(*namespace_keys, key)
      end
    end
  end
end
