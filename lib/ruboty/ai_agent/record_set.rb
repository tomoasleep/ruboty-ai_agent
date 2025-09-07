# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records.
    # @rbs generic Record
    class RecordSet
      attr_reader :database #: Ruboty::AiAgent::Database

      def initialize(database:)
        @database = database
      end

      def namespace_keys #: Array[Symbol | String | Integer]
        raise NotImplementedError, 'Subclasses must implement the namespace_keys method'
      end

      def length #: Integer
        database.len(*namespace_keys)
      end

      def all #: untyped
        database.fetch(*namespace_keys)
      end

      def all_values #: Array[Record]
        case (kv = all)
        when Hash
          kv.values
        when Array
          kv
        else
          []
        end
      end

      def keys #: Array[Database::keynable]
        database.keys(*namespace_keys)
      end

      # @rbs key: Symbol | String | Integer
      # @rbs return: Record | nil
      def fetch(key)
        database.fetch(*namespace_keys, key)
      end

      # @rbs key: Symbol | String | Integer
      # @rbs record: Record
      # @rbs return: void
      def store(record, key:)
        database.store(record, at: [*namespace_keys, key])
      end

      # @rbs key: String | Integer
      # @rbs return: void
      def remove(key)
        database.delete(*namespace_keys, key)
      end

      def key?(key)
        database.key?(*namespace_keys, key)
      end
    end
  end
end
