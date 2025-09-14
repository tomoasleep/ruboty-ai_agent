#!/usr/bin/env ruby
# frozen_string_literal: true

# Clean orphaned RBS files from sig/generated
#
# This script removes RBS files from sig/generated directory that don't have
# corresponding Ruby files in the project.

require 'fileutils'
require 'pathname'

# Remove orphaned RBS files by `rbs-inline`
class OrphanedRbsCleaner
  def initialize(project_root: Dir.pwd)
    @project_root = Pathname.new(project_root)
    @sig_generated_dir = @project_root / 'sig' / 'generated'
    @removed_files = []
    @kept_files = []
  end

  def run(dry_run: false)
    return unless @sig_generated_dir.exist?

    puts "Scanning for orphaned RBS files in #{@sig_generated_dir}..."

    rbs_files = find_rbs_files
    puts "Found #{rbs_files.size} RBS files to check"

    rbs_files.each do |rbs_file|
      corresponding_ruby_file = find_corresponding_ruby_file(rbs_file)

      if corresponding_ruby_file&.exist?
        @kept_files << rbs_file
      else
        @removed_files << rbs_file
        if dry_run
          puts "Would remove: #{rbs_file.relative_path_from(@project_root)}"
        else
          puts "Removing: #{rbs_file.relative_path_from(@project_root)}"
          rbs_file.delete
        end
      end
    end

    cleanup_empty_directories unless dry_run

    print_summary
  end

  private

  def find_rbs_files
    @sig_generated_dir.glob('**/*.rbs').sort
  end

  def find_corresponding_ruby_file(rbs_file)
    # Convert sig/generated/path/to/file.rbs to possible Ruby file locations
    relative_path = rbs_file.relative_path_from(@sig_generated_dir)
    ruby_file_name = relative_path.sub_ext('.rb')

    # Check common Ruby source directories
    possible_locations = [
      @project_root / 'lib' / ruby_file_name
    ]

    possible_locations.find(&:exist?)
  end

  def cleanup_empty_directories
    # Remove empty directories in sig/generated
    @sig_generated_dir.find do |path|
      next unless path.directory?
      next if path == @sig_generated_dir

      begin
        path.rmdir if path.empty?
      rescue Errno::ENOTEMPTY
        # Directory is not empty, skip
      end
    end
  end

  def print_summary
    puts "\nSummary:"
    puts "  Kept files: #{@kept_files.size}"
    puts "  Removed files: #{@removed_files.size}"

    return unless @removed_files.any?

    puts "\nRemoved files:"
    @removed_files.each do |file|
      puts "  - #{file.relative_path_from(@project_root)}"
    end
  end
end

# Script execution
if __FILE__ == $PROGRAM_NAME
  dry_run = ARGV.include?('--dry-run')

  puts 'Running in dry-run mode (no files will be deleted)' if dry_run

  cleaner = OrphanedRbsCleaner.new
  cleaner.run(dry_run: dry_run)
end
