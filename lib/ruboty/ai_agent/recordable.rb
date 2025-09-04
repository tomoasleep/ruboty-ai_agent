# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Convertable between Hash and Recordable bidirectionally.
    module Recordable
      class << self
        def included(base)
          base.extend(ClassMethods)
          base.prepend(PrependFeatures)

          base.instance_exec do
            attr_accessor :record_type
          end
        end

        def record_types #: Hash[Symbol, Class]
          @record_types ||= {}
        end

        # @rbs hash: Hash[Symbol, untyped]
        # @rbs return: bool
        def convertable?(hash)
          return false unless hash.is_a?(Hash)

          type = hash[:record_type]
          type && record_types.include?(type)
        end

        # @rbs value: untyped
        # @rbs return: untyped
        def convert_recursively(value)
          case value
          when Hash
            if convertable?(value)
              record_from_hash(value)
            else
              value.transform_values { |v| convert_recursively(v) }
            end
          when Array
            value.map { |v| convert_recursively(v) }
          else
            value
          end
        end

        # @rbs record: Recordable
        # @rbs return: Hash
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

      module ClassMethods
        # @rbs name: String
        def register_record_type(name)
          name = name.to_sym
          self.record_type = name

          Recordable.record_types.merge!({ name => self }) do
            raise "Duplicate record type: #{name}"
          end
        end
      end

      module PrependFeatures
        def to_h #: Hash
          {
            record_type: self.class.record_type,
            **super
          }
        end
      end
    end
  end
end
