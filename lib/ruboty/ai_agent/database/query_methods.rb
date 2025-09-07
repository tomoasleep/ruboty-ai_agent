# frozen_string_literal: true

module Ruboty
  module AiAgent
    class Database
      # @rbs!
      #   interface _WithData
      #     def data: -> Hash[keynable, untyped]
      #   end

      # @rbs module-self _WithData
      module QueryMethods
        # @rbs *keys: keynable
        # @rbs return: untyped
        def fetch(*keys)
          item = data.dig(*keys)

          Recordable.instantiate_recursively(item)
        end

        # @rbs *keys: keynable
        # @rbs return: Integer
        def len(*keys)
          item = data.dig(*keys)
          item.respond_to?(:length) ? item.length : 0
        end

        # @rbs *keys: keynable
        # @rbs return: void
        def delete(*keys)
          namespace_keys = keys[0..-2] || []
          key = keys[-1]

          namespace = namespace_keys.empty? ? data : data.dig(*namespace_keys) #: top
          case namespace
          when Hash
            namespace.delete(key)
          when Array
            namespace.delete_at(key) if key.is_a?(Integer) && key < namespace.length
          end
        end

        # @rbs *keys: keynable
        # @rbs return: Array[keynable]
        def keys(*keys)
          namespace = keys.empty? ? data : data.dig(*keys) #: top
          case namespace
          when Hash
            namespace.keys
          when Array
            namespace.length.times.to_a
          else
            []
          end
        end

        # @rbs *keys: keynable
        # @rbs return: boolish
        def key?(*keys)
          namespace_keys = keys[0..-2] || []
          key = keys[-1]

          namespace = namespace_keys.empty? ? data : data.dig(*namespace_keys)
          namespace&.key?(key)
        end

        # @rbs at: Array[keynable]
        # @rbs value: untyped
        # @rbs return: void
        def store(value, at:)
          namespace_keys = at[0..-2] || []
          key = at[-1]

          namespace = namespace_keys.reduce(data) do |current, k|
            current[k] ||= {}
            current[k]
          end

          namespace[key] = Recordable.hashify_recursively(value)
        end
      end
    end
  end
end
