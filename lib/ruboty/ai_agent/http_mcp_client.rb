# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'

module Ruboty
  module AiAgent
    # Mcp client with HTTP transport.
    class HttpMcpClient
      attr_reader :base_url, :headers, :session_id

      def initialize(url, headers: {})
        @base_url = url
        @headers = headers
        @session_id = nil
      end

      def initialize_session
        response = send_request(
          method: 'initialize',
          params: {
            protocolVersion: '2024-11-05',
            capabilities: {},
            clientInfo: {
              name: 'ruboty-ai_agent',
              version: '1.0'
            }
          }
        )

        @session_id = response['Mcp-Session-Id']
        @session_id
      end

      def ping
        send_request(method: 'ping')
      end

      def list_tools
        send_request(method: 'tools/list')
      end

      def call_tool(name, arguments = {})
        send_request(
          method: 'tools/call',
          params: {
            name: name,
            arguments: arguments
          }
        )
      end

      def list_prompts
        send_request(method: 'prompts/list')
      end

      def get_prompt(name, arguments = {})
        send_request(
          method: 'prompts/get',
          params: {
            name: name,
            arguments: arguments
          }
        )
      end

      def list_resources
        send_request(method: 'resources/list')
      end

      def read_resource(uri)
        send_request(
          method: 'resources/read',
          params: {
            uri: uri
          }
        )
      end

      def cleanup_session
        return unless @session_id

        uri = URI.parse(@base_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Delete.new(uri.path.empty? ? '/' : uri.path)
        request['Content-Type'] = 'application/json'
        request['Mcp-Session-Id'] = @session_id
        headers.each { |k, v| request[k] = v }

        http.request(request)
        @session_id = nil
      end

      private

      def send_request(method:, params: nil, id: nil)
        uri = URI.parse(@base_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
        request['Content-Type'] = 'application/json'
        request['Mcp-Session-Id'] = @session_id if @session_id
        headers.each { |k, v| request[k] = v }

        body = {
          jsonrpc: '2.0',
          method: method,
          id: id || SecureRandom.uuid
        }
        body[:params] = params if params

        request.body = JSON.generate(body)

        response = http.request(request)

        @session_id = response['Mcp-Session-Id'] if method == 'initialize'

        handle_response(response)
      end

      def handle_response(response)
        raise Error, "HTTP #{response.code}: #{response.body}" unless response.code.to_i == 200

        result = JSON.parse(response.body)

        raise Error, "JSON-RPC Error #{result['error']['code']}: #{result['error']['message']}" if result['error']

        result['Mcp-Session-Id'] = response['Mcp-Session-Id'] if response['Mcp-Session-Id']

        result['result'] || result
      end

      class Error < StandardError; end
    end
  end
end
