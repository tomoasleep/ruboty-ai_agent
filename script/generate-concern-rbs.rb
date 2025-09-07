#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate RBS definitions for classes/modules that include concern modules
#
# This script detects concern modules (modules with ClassMethods or PrependMethods)
# and generates extend/prepend declarations for classes that include them.
#
# Example Ruby code:
#
#   module Trackable
#     def self.included(base)
#       base.extend(ClassMethods)
#       base.prepend(PrependMethods)
#     end
#
#     module ClassMethods
#       def track_method(name)
#         # ...
#       end
#     end
#
#     module PrependMethods
#       def initialize(*)
#         super
#         # tracking logic
#       end
#     end
#   end
#
#   class User
#     include Trackable
#   end
#
# Existing RBS:
#
#   module Trackable
#     module ClassMethods
#       def track_method: (Symbol) -> void
#     end
#
#     module PrependMethods
#       def initialize: (*untyped) -> void
#     end
#   end
#
#   class User
#     include Trackable
#   end
#
# This script will generate:
#
#   class User
#     extend Trackable::ClassMethods
#     prepend Trackable::PrependMethods
#   end
#
# The script:
# 1. Loads existing RBS definitions from sig/ directory
# 2. Finds modules that have ClassMethods or PrependMethods submodules
# 3. Finds classes/modules that include these concern modules
# 4. Generates appropriate extend/prepend declarations

require 'rbs'
require 'rbs/environment'
require 'pathname'
require 'fileutils'

# Process Ruby source files and RBS definitions to generate concern RBS
class ConcernRbsGenerator
  def initialize(lib_path: 'lib', sig_path: 'sig', output_path: 'sig/generated-by-scripts', namespace_filter: nil)
    @lib_path = Pathname(lib_path)
    @sig_path = Pathname(sig_path)
    @output_path = Pathname(output_path)
    @namespace_filter = namespace_filter
    @env = RBS::Environment.new
  end

  def process
    load_rbs_environment
    generate_concern_rbs
  end

  private

  def load_rbs_environment
    puts 'Loading RBS environment...'

    # Load standard library RBS
    loader = RBS::EnvironmentLoader.new

    # Add sig subdirectories, excluding generated-by-scripts
    Pathname('sig').children.select(&:directory?).each do |dir|
      next if dir.basename.to_s == 'generated-by-scripts'

      loader.add(path: dir)
    end

    # Add RBS files directly in sig directory
    loader.add(path: Pathname('sig'))

    loader.add(path: Pathname('.gem_rbs_collection'))
    loader.load(env: @env)

    puts "Loaded #{@env.class_decls.size} class declarations"
    puts "Loaded #{@env.interface_decls.size} interface declarations"
  end

  def generate_concern_rbs
    puts "\nGenerating concern RBS..."

    concern_modules = find_concern_modules
    includers = find_concern_includers(concern_modules)

    if includers.empty?
      puts 'No classes/modules found that include concern modules'
      return
    end

    puts "\nFound #{includers.size} classes/modules that include concerns:"
    includers.each do |includer|
      puts "  - #{includer[:name]} includes #{includer[:concern][:name]}"
    end

    rbs_content = generate_rbs_content(includers)

    return unless rbs_content

    FileUtils.mkdir_p(@output_path)
    output_file = @output_path / 'concerns.rbs'
    File.write(output_file, rbs_content)
    puts "\nGenerated #{output_file}"
  end

  def find_concern_modules
    concern_modules = []

    @env.class_decls.each do |type_name, decl|
      # Skip if not a module
      next unless decl.primary.decl.is_a?(RBS::AST::Declarations::Module)

      module_name = type_name.to_s

      # Filter by namespace if specified
      next if @namespace_filter && !module_name.start_with?("::#{@namespace_filter}")

      # Check if module has a ClassMethods submodule
      class_methods_name = RBS::TypeName.new(
        namespace: RBS::Namespace.new(path: type_name.namespace.path + [type_name.name], absolute: type_name.namespace.absolute?),
        name: :ClassMethods
      )

      # Check if module has a PrependMethods submodule
      prepend_methods_name = RBS::TypeName.new(
        namespace: RBS::Namespace.new(path: type_name.namespace.path + [type_name.name], absolute: type_name.namespace.absolute?),
        name: :PrependMethods
      )

      has_class_methods = @env.class_decls.key?(class_methods_name)
      has_prepend_methods = @env.class_decls.key?(prepend_methods_name)

      next unless has_class_methods || has_prepend_methods

      concern_modules << {
        name: module_name,
        type_name: type_name,
        has_class_methods: has_class_methods,
        has_prepend_methods: has_prepend_methods
      }
    end

    concern_modules
  end

  def find_concern_includers(concern_modules)
    includers = []

    @env.class_decls.each do |type_name, decl|
      # Filter by namespace if specified
      next if @namespace_filter && !type_name.to_s.start_with?("::#{@namespace_filter}")

      # Check all declarations (primary and others) for includes
      all_decls = [decl.primary] + decl.decls

      includes = []
      is_class = false

      all_decls.each do |d|
        case d.decl
        when RBS::AST::Declarations::Class
          is_class = true
          d.decl.members.each do |member|
            case member
            when RBS::AST::Members::Include
              # Resolve the included module name to full TypeName
              included_type_name = resolve_type_name(member.name, type_name.namespace)
              includes << included_type_name if included_type_name
            end
          end
        when RBS::AST::Declarations::Module
          d.decl.members.each do |member|
            case member
            when RBS::AST::Members::Include
              # Resolve the included module name to full TypeName
              included_type_name = resolve_type_name(member.name, type_name.namespace)
              includes << included_type_name if included_type_name
            end
          end
        end
      end

      # Check if any of the includes are concern modules
      includes.uniq.each do |included_name|
        concern = concern_modules.find do |c|
          c[:type_name] == included_name
        end

        next unless concern

        includers << {
          name: type_name.to_s,
          type_name: type_name,
          is_class: is_class,
          concern: concern
        }
      end
    end

    includers
  end

  def resolve_type_name(name, current_namespace)
    # If the name is already absolute, use it as is
    return name if name.absolute?

    # Otherwise, resolve relative to current namespace
    RBS::TypeName.new(
      namespace: current_namespace,
      name: name.name
    )
  end

  def generate_rbs_content(includers)
    content = []
    content << '# Generated RBS definitions for concern modules'
    content << '# This file is automatically generated by script/generate-concern-rbs.rb'
    content << ''

    # Group by namespace for cleaner output
    grouped = includers.group_by do |includer|
      parts = includer[:name].sub(/^::/, '').split('::')
      parts[0...-1]
    end

    grouped.each do |namespace_parts, group_includers|
      indent_level = 0

      # Open namespaces
      namespace_parts.each do |part|
        content << ('  ' * indent_level) + "module #{part}"
        indent_level += 1
      end

      # Add extend/prepend for each includer in this namespace
      group_includers.each do |includer|
        simple_name = includer[:name].sub(/^::/, '').split('::').last
        keyword = includer[:is_class] ? 'class' : 'module'

        content << ('  ' * indent_level) + "#{keyword} #{simple_name}"

        concern = includer[:concern]
        concern_simple_name = concern[:name].sub(/^::/, '').split('::').last

        content << ('  ' * (indent_level + 1)) + "extend #{concern_simple_name}::ClassMethods" if concern[:has_class_methods]

        content << ('  ' * (indent_level + 1)) + "prepend #{concern_simple_name}::PrependMethods" if concern[:has_prepend_methods]

        content << "#{'  ' * indent_level}end"
        content << ''
      end

      # Close namespaces
      namespace_parts.size.times do
        indent_level -= 1
        content << "#{'  ' * indent_level}end"
      end

      content << ''
    end

    content.join("\n").strip
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  generator = ConcernRbsGenerator.new(namespace_filter: 'Ruboty')
  generator.process
end
