# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Memorize and retrieve information using Ruboty's brain.
    class Database
      NAMESPACE = 'ai_agent'

      # @rbs brain: Ruboty::Brain::Base
      def initialize(brain)
        @brain = brain
      end

      def data #: Hash
        @brain.data[NAMESPACE] ||= {}
      end

      # @rbs keys: Array[Symbol | Integer]
      # @rbs return: untyped
      def fetch(*keys)
        item = data.dig(*keys)

        Recordable.convert_recursively(item)
      end

      # @rbs keys: Array[Symbol | Integer]
      # @rbs return: Integer
      def len(*keys)
        item = data.dig(*keys)
        item.respond_to?(:length) ? deserialized_item.length : 0
      end

      # @rbs keys: Array[Symbol | Integer]
      # @rbs return: void
      def delete(*keys)
        namespace_keys = keys[0..-2]
        key = keys[-1]

        namespace = namespace_keys.empty? ? data : data.dig(*namespace_keys)
        case namespace
        when Hash
          namespace.delete(key)
        when Array
          namespace.delete_at(key) if key.is_a?(Integer) && key < namespace.length
        end
      end

      # @rbs keys: Array[Symbol | Integer]
      # @rbs return: Array[Symbol | Integer]
      def keys(*keys) #: boolish
        namespace = keys.empty? ? data : data.dig(*keys)
        case namespace
        when Hash
          namespace.keys
        when Array
          namespace.lenght.times.to_a
        else
          []
        end
      end

      # @rbs keys: Array[Symbol | Integer]
      # @rbs return: boolish
      def key?(*keys) #: boolish
        namespace_keys = keys[0..-2]
        key = keys[-1]

        namespace = namespace_keys.empty? ? data : data.dig(*namespace_keys)
        namespace&.key?(key)
      end

      # @rbs at: Array[String | Integer]
      # @rbs value: untyped
      # @rbs return: void
      def store(value, at:)
        namespace_keys = at[0..-2]
        key = at[-1]

        namespace = namespace_keys.reduce(data) do |current, k|
          current[k] ||=
            if k.is_a?(Integer)
              []
            else
              {}
            end

          current[k]
        end

        namespace[key] = value.to_json
      end

      def user(id) #: User
        User.find_or_create(database: self, id: id)
      end

      def chat_thread(id) #: ChatThread
        ChatThread.find_or_create(database: self, id: id)
      end
    end
  end
end
