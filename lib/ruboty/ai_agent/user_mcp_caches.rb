# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage MCP caches for a specific user.
    # @abstract
    # @rbs generic D < Object
    class UserMcpCaches < UserAssociations #[CachedValue[D]]
      # @rbs!
      #   def self.cache_type_key: () -> Symbol?
      #   def self.cache_type_key=: (Symbol?) -> Symbol?

      # @rbs!
      #   def self.cache_duration: () -> Integer?
      #   def self.cache_duration=: (Integer?) -> Integer?

      class << self
        # @rbs skip
        attr_accessor :cache_type_key
        # @rbs skip
        attr_accessor :cache_duration

        def association_key #: Symbol
          raise 'Subclasses must set the cache_type_key method' unless cache_type_key

          :"mcp_caches:#{cache_type_key}"
        end
      end

      def cache_type_key #: Symbol
        self.class.cache_type_key || raise(NotImplementedError, 'Subclasses must set the cache_type_key method')
      end

      def cache_duration #: Integer
        self.class.cache_duration || raise(NotImplementedError, 'Subclasses must set the cache_duration method')
      end

      # @rbs key: String)
      # @rbs &block: () -> (D | CachedValue[D])
      # @rbs return: D
      def fetch_or_store_data(key, &block)
        if (fetched = fetch_data(key))
          fetched
        else
          data = block.call
          cache = data.is_a?(CachedValue) ? data : CachedValue.new(data:, expires_at: Time.now + cache_duration)
          store(cache, key:)
          cache.data
        end
      end

      # @rbs key: String
      # @rbs return: D?
      def fetch_data(key)
        fetch(key)&.data
      end

      # @rbs override
      def all
        super().reject { |(_key, cache)| cache.expired? }
      end

      # @rbs override
      def fetch(key)
        cache = super(key)

        if cache&.expired?
          remove(key)
          nil
        end

        cache
      end

      # @rbs key: String
      # @rbs data: D
      # @rbs return: void
      def store_data(data, key:)
        expires_at = Time.now + cache_duration

        cache = CachedValue.new(
          data:,
          expires_at:
        ) #: CachedValue[D]

        store(cache, key:)
      end
    end
  end
end
