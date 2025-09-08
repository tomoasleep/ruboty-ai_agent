# frozen_string_literal: true

require 'time'

module Ruboty
  module AiAgent
    # Cache for MCP operations
    # @rbs generic D < Object
    class CachedValue
      include Recordable

      attr_reader :expires_at #: Time
      attr_reader :data #: D

      # @rbs data: D
      # @rbs expires_at: Time
      def initialize(data:, expires_at:)
        @data = data
        @expires_at = expires_at.is_a?(Time) ? expires_at.round : Time.parse(expires_at)
      end

      # @rbs return: Hash[Symbol, untyped]
      def to_h
        {
          expires_at: expires_at.rfc2822,
          data: data
        }
      end

      # @rbs return: bool
      def expired?
        Time.now > expires_at
      end

      # @rbs return: bool
      def valid?
        !expired?
      end

      register_record_type :mcp_cache
    end
  end
end
