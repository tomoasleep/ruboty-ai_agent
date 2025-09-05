# frozen_string_literal: true

require 'optparse'

module Ruboty
  module AiAgent
    module Actions
      # AddMcp action for Ruboty::AiAgent
      class AddMcp < Base
        def call
          options = parse_config

          case options[:transport]
          when 'http'
            url = options[:args].first
            if url
              new_mcp_configuration = McpConfiguration.new(
                transport: 'http',
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

          when 'sse'
            message.reply('Error: SSE transport is not yet implemented.')
          else
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

        # @rbs! type config = { transport: "http" | "sse", headers: Array[String], args: Array[String] }

        def parse_config #: config
          options = {
            transport: 'http',
            headers: [],
            args: []
          }

          return options unless config_param

          args = config_param.split(/\s+(?=-)/)

          parser = OptionParser.new do |opts|
            opts.on('--transport TYPE', %w[http sse], 'Transport type (http or sse)') do |t|
              options[:transport] = t
            end

            opts.on('--header VALUE', 'Add a header (can be specified multiple times)') do |h|
              options[:headers] << h
            end
          end

          options[:args] = parser.parse(args)

          options
        end
      end
    end
  end
end
