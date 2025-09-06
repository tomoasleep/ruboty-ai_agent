# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'
require 'event_stream_parser'

module Ruboty
  module AiAgent
    # Mcp client with HTTP transport.
    class HttpMcpClient
      attr_reader :base_url, :headers, :session_id

      def initialize(url:, headers: {}, session_id: nil)
        @base_url = url
        @headers = headers
        @session_id = session_id

        @initialize_called = false
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
        ).first

        @session_id = response['Mcp-Session-Id'] if response.is_a?(Hash) && response['Mcp-Session-Id']
        @initialize_called = true
        @session_id
      end

      def ping
        ensure_initialized
        send_request(method: 'ping')
      end

      def list_tools
        ensure_initialized
        results = send_request(method: 'tools/list')
        results.flat_map { |res| res.dig('result', 'tools') || [] }
      end

      def call_tool(name, arguments = {}, &block)
        ensure_initialized
        results = send_request(
          method: 'tools/call',
          params: {
            name: name,
            arguments: arguments
          },
          &block
        )

        return nil if block_given?

        results.flat_map { |res| res.dig('result', 'content') || [] }
      end

      def list_prompts
        ensure_initialized
        send_request(method: 'prompts/list')
      end

      def get_prompt(name, arguments = {})
        ensure_initialized
        send_request(
          method: 'prompts/get',
          params: {
            name: name,
            arguments: arguments
          }
        )
      end

      def list_resources
        ensure_initialized
        send_request(method: 'resources/list')
      end

      def read_resource(uri)
        ensure_initialized
        send_request(
          method: 'resources/read',
          params: {
            uri: uri
          }
        )
      end

      def cleanup_session
        if @session_id
          uri = URI.parse(@base_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'

          request = Net::HTTP::Delete.new(uri.path.empty? ? '/' : uri.path)
          request['Accept'] = 'application/json, text/event-stream'
          request['Content-Type'] = 'application/json'
          request['Mcp-Session-Id'] = @session_id
          headers.each { |k, v| request[k] = v }

          http.request(request)
          @session_id = nil
        end

        @initialize_called = false
      end

      private

      def ensure_initialized
        return if @initialize_called || @session_id

        initialize_session
      end

      def send_request(method:, params: nil, id: nil, &block) #: Array[Hash] | nil
        uri = URI.parse(@base_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'

        request = Net::HTTP::Post.new(uri.path.empty? ? '/' : uri.path)
        request['Accept'] = 'application/json, text/event-stream'
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
        raise Error, "HTTP #{response.code}: #{response.body}" unless response.code.to_i == 200

        @session_id = response['Mcp-Session-Id'] if method == 'initialize'

        if response['Content-Type'] =~ %r{text/event-stream}
          handle_streaming_response(response, &block)
        else
          handle_response(response)
        end
      end

      def handle_response(response, &block)
        result = JSON.parse(response.body)

        raise Error, "JSON-RPC Error #{result['error']['code']}: #{result['error']['message']}" if result['error']

        result['Mcp-Session-Id'] = response['Mcp-Session-Id'] if response['Mcp-Session-Id']

        if block
          block.call([result])
        else
          [result]
        end
      end

      def handle_streaming_response(response, &block)
        events = []
        parser = EventStreamParser::Parser.new

        body = response.body
        parser.feed(body) do |_type, data, _id, _reconnection_time|
          next if data.nil? || data.empty?

          begin
            parsed_data = JSON.parse(data)
            raise Error, "JSON-RPC Error #{parsed_data['error']['code']}: #{parsed_data['error']['message']}" if parsed_data['error']

            if block_given?
              block.call(parsed_data)
            else
              events << parsed_data
            end
          rescue JSON::ParserError => e
            raise Error, "Failed to parse SSE data: #{e.message}"
          end
        end

        events unless block_given?
      end

      class Error < StandardError; end
    end
  end
end
