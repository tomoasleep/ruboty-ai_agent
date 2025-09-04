# frozen_string_literal: true

require 'openai'
require 'mcp'

module Ruboty
  module AiAgent
    # Agent class to interact with LLM and manage conversations.
    class Agent
      DEFAULT_MODEL = 'gpt-4o'
      DEFAULT_MAX_TOKENS = 2000

      attr_reader :client, :messages, :system_prompt, :mcp_clients, :model, :max_tokens

      def initialize(
        client:,
        messages: [],
        system_prompt: nil,
        mcp_servers: [],
        model: DEFAULT_MODEL,
        max_tokens: DEFAULT_MAX_TOKENS
      )
        @client = client

        @messages = initialize_messages(messages, system_prompt)
        @system_prompt = system_prompt
        @mcp_clients = initialize_mcp_clients(mcp_servers)
        @model = model
        @max_tokens = max_tokens
      end

      def chat(user_input, stream: false, &block)
        @messages << { role: 'user', content: user_input }

        parameters = {
          model: @model,
          messages: @messages,
          max_tokens: @max_tokens
        }

        if @mcp_clients.any?
          tools = fetch_available_tools
          parameters[:tools] = tools if tools.any?
        end

        if stream && block_given?
          parameters[:stream] = proc do |chunk, _event|
            content = chunk.dig('choices', 0, 'delta', 'content')
            block.call(content) if content
          end
        end

        response = @client.chat(parameters: parameters)

        if stream
          # For streaming, the response is already handled via the block
          return nil
        end

        assistant_message = response.dig('choices', 0, 'message')

        if assistant_message
          @messages << assistant_message

          # Handle tool calls if present
          if assistant_message['tool_calls']
            handle_tool_calls(assistant_message['tool_calls'])
            # Make another request to get the final response
            return chat_without_user_input
          end

          assistant_message['content']
        end
      rescue StandardError => e
        handle_error(e)
      end

      private

      def initialize_messages(messages, system_prompt)
        return messages.dup if messages.any? && messages.first[:role] == 'system'

        initial_messages = []
        initial_messages << { role: 'system', content: system_prompt } if system_prompt
        initial_messages + messages
      end

      def initialize_mcp_clients(mcp_servers)
        mcp_servers.map do |server_config|
          case server_config[:type]
          when 'http'
            Mcp::HttpClient.new(
              url: server_config[:url],
              headers: server_config[:headers] || {}
            )
          when 'stdio'
            Mcp::StdioClient.new(
              command: server_config[:command],
              args: server_config[:args] || []
            )
          else
            raise "Unknown MCP server type: #{server_config[:type]}"
          end
        end
      rescue StandardError => e
        # If MCP initialization fails, continue without it
        puts "Warning: Failed to initialize MCP clients: #{e.message}"
        []
      end

      def fetch_available_tools
        tools = []
        @mcp_clients.each do |mcp_client|
          mcp_tools = mcp_client.list_tools
          tools.concat(convert_mcp_tools_to_openai_format(mcp_tools))
        rescue StandardError => e
          puts "Warning: Failed to fetch tools from MCP client: #{e.message}"
        end
        tools
      end

      def convert_mcp_tools_to_openai_format(mcp_tools)
        mcp_tools.map do |tool|
          {
            type: 'function',
            function: {
              name: tool['name'],
              description: tool['description'],
              parameters: tool['inputSchema'] || {
                type: 'object',
                properties: {},
                required: []
              }
            }
          }
        end
      end

      def handle_tool_calls(tool_calls)
        tool_results = []

        tool_calls.each do |tool_call|
          tool_call_id = tool_call['id']
          function_name = tool_call.dig('function', 'name')
          function_args = JSON.parse(
            tool_call.dig('function', 'arguments'),
            { symbolize_names: true }
          )

          result = execute_tool(function_name, function_args)

          tool_results << {
            tool_call_id: tool_call_id,
            role: 'tool',
            name: function_name,
            content: result.to_s
          }
        end

        @messages.concat(tool_results)
      end

      def execute_tool(function_name, arguments)
        @mcp_clients.each do |mcp_client|
          tools = mcp_client.list_tools
          return mcp_client.call_tool(function_name, arguments) if tools.any? { |t| t['name'] == function_name }
        rescue StandardError => e
          puts "Error executing tool #{function_name}: #{e.message}"
        end

        "Tool #{function_name} not found or execution failed"
      end

      def chat_without_user_input
        parameters = {
          model: @model,
          messages: @messages,
          max_tokens: @max_tokens
        }

        response = @client.chat(parameters: parameters)
        assistant_message = response.dig('choices', 0, 'message')

        return unless assistant_message

        @messages << assistant_message
        assistant_message['content']
      end

      def handle_error(error)
        raise "OpenAI API error: #{error.message}" if defined?(Faraday::Error) && error.is_a?(Faraday::Error)

        raise error
      end
    end
  end
end
