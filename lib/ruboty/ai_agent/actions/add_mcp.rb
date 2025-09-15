# frozen_string_literal: true

require 'optparse'
require 'shellwords'

module Ruboty
  module AiAgent
    module Actions
      # AddMcp action for Ruboty::AiAgent
      class AddMcp < Base
        def call
          options = parse_config

          case options[:transport]
          when :http
            url = options[:args].first #: String?
            if url
              new_mcp_configuration = McpConfiguration.new(
                transport: :http,
                name: name_param,
                headers: options[:headers],
                url: url
              )
              user.mcp_configurations.add(
                new_mcp_configuration
              )

              message.reply("Added MCP configuration #{name_param}: #{new_mcp_configuration.to_h.except(:record_type).to_json}")
            else
              message.reply('Error: URL is required for HTTP transport. Please specify the URL as an argument.')
              nil
            end

          when :sse
            message.reply('Error: SSE transport is not yet implemented.')
          else # steep:ignore UnreachableValueBranch
            message.reply('Error: Invalid or missing transport type. Please specify --transport http or --transport sse.')
          end
        rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
          message.reply("Error parsing options: #{e.message}")
        end

        def name_param #: String
          message[:name]
        end

        def config_param #: String
          message[:config]
        end

        private

        # @rbs! type config = { transport: :http | :sse, headers: Hash[String, String], args: Array[String] }

        def parse_config #: config
          options = {
            transport: :http,
            headers: {},
            args: []
          } #: config

          args = config_param.shellsplit

          parser = OptionParser.new do |opts|
            opts.on('--transport TYPE', %w[http sse], 'Transport type (http or sse)') do |t|
              options[:transport] = t.to_sym
            end

            opts.on('--header VALUE', 'Add a header (can be specified multiple times)') do |h|
              key, value = undump_string(h).split(':', 2).map!(&:strip)
              unless key && value
                message.reply("Warning: Invalid format for --header '#{h}'. Expected format is 'Key: Value'.")
                next
              end

              options[:headers][key] = value
            end

            opts.on('--bearer-token TOKEN', 'Set Authorization Bearer token (shorthand for --header "Authorization: Bearer TOKEN")') do |token|
              options[:headers]['Authorization'] = "Bearer #{token}"
            end
          end

          options[:args] = parser.parse(args)

          options
        end

        # @rbs str: String
        # @rbs return: String
        def undump_string(str)
          str.undump
        rescue StandardError
          str
        end
      end
    end
  end
end
