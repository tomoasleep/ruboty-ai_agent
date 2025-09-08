# frozen_string_literal: true

module Ruboty
  module AiAgent
    # @rbs!
    #   interface _WithToH
    #     def to_h: () -> Hash[Database::keynable, untyped]
    #   end

    # Convertable between Hash and Recordable bidirectionally.
    # @rbs module-self _WithToH
    module Recordable
      class << self
        def included(base)
          base.extend(ClassMethods)
          base.prepend(PrependMethods)
        end

        # @rbs @record_types: Hash[Symbol, Class]

        def record_types #: Hash[Symbol, Class]
          @record_types ||= {}
        end

        # @rbs hash: Hash[Symbol, untyped]?
        # @rbs return: bool
        def convertable?(hash)
          return false unless hash.is_a?(Hash)

          type = hash[:record_type]
          type && record_types.include?(type)
        end

        # @rbs value: untyped
        # @rbs return: untyped
        def instantiate_recursively(value)
          case value
          when Hash
            transformed = value.transform_values { |v| instantiate_recursively(v) }
            if convertable?(transformed)
              record_from_hash(transformed)
            else
              transformed
            end
          when Array
            value.map { |v| instantiate_recursively(v) }
          else
            value
          end
        end

        # @rbs value: untyped
        # @rbs return: untyped
        def hashify_recursively(value)
          case value
          when Recordable
            hashify_recursively(value.to_h)
          when Hash
            value.transform_values { |v| hashify_recursively(v) }
          when Array
            value.map { |v| hashify_recursively(v) }
          else
            value
          end
        end

        # @rbs record: Recordable
        # @rbs return: Hash[Database::keynable, untyped]
        def record_to_hash(record)
          record.to_h
        end

        # @rbs hash: Hash[Symbol, untyped]
        # @rbs return: Recordable
        def record_from_hash(hash)
          type = hash[:record_type]
          klass = record_types[type]
          raise "Unknown record type: #{type}" unless klass

          klass.new(**hash.except(:record_type))
        end
      end

      # @rbs module-self Class
      module ClassMethods
        attr_accessor :record_type #: Symbol

        # @rbs name: Symbol
        def register_record_type(name)
          name = name.to_sym
          self.record_type = name

          Recordable.record_types.merge!({ name => self }) do
            raise "Duplicate record type: #{name}"
          end
        end
      end

      # @rbs module-self Recordable::ClassMethods.instance
      module PrependMethods
        def to_h #: Hash[Database::keynable, untyped]
          {
            record_type: record_type,
            **super
          }
        end
      end

      # @rbs %a{pure}
      def record_type #: Symbol
        self.class #: singleton(::Object) & ClassMethods
            .record_type
      end
    end
  end
end
