# frozen_string_literal: true

module Ruboty
  module AiAgent
    module Actions
      # ListMcp action for Ruboty::AiAgent
      class ListMcp < Base
        def call
          clients = user.mcp_clients

          if clients.empty?
            message.reply('No MCP servers found.')
            return
          end

          show_headers = !message[:with_headers].nil?
          output = clients.map do |mcp_client|
            format_mcp_client(mcp_client, show_headers: show_headers)
          end.join("\n\n")

          message.reply(output)
        end

        private

        # @rbs client: UserMcpClient
        # @rbs show_headers: bool
        # @rbs return: String
        def format_mcp_client(client, show_headers: false)
          configuration = client.configuration

          tools_info = format_tools(client)
          mcp_info = <<~TEXT
            #{configuration.name}:
              Transport: #{configuration.transport}
              URL: #{configuration.url}
          TEXT

          mcp_info += "  Headers: #{configuration.headers.to_json}\n" if show_headers

          "#{mcp_info}#{tools_info}".chomp
        end

        # @rbs client: UserMcpClient
        # @rbs return: String
        def format_tools(client)
          tools = client.list_tools
          return '' if tools.empty?

          tools_output = tools.map do |tool|
            tool_name = tool['name'] || 'unnamed'
            description = tool['description'] || 'No description'
            truncated_description = description.length > 100 ? "#{description[0, 100]}..." : description
            "  - #{tool_name}: #{truncated_description}"
          end.join("\n")

          "  Tools:\n#{tools_output}\n"
        rescue HttpMcpClient::Error => e
          warn "Failed to list tools for MCP client: #{e.message}"
          ''
        end
      end
    end
  end
end
