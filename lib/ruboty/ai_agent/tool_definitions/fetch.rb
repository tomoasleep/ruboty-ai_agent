# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'net/https'

module Ruboty
  module AiAgent
    module ToolDefinitions
      # Fetch and extract readable content from web pages using ruby-readability
      class Fetch < Base
        class FetchError < StandardError; end

        self.tool_name = 'fetch'
        self.tool_title = 'Fetch Web Page Content'

        self.tool_description = <<~TEXT
          Fetch and extract readable content from a web page using ruby-readability.
          This tool downloads the HTML from a URL and extracts the main readable text,
          filtering out navigation, ads, and other boilerplate content.
        TEXT

        self.tool_input_schema = {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'The URL of the web page to fetch.'
            }
          },
          required: ['url']
        }

        class << self
          # @rbs @available: bool

          def avaliable!
            @available = true
          end

          def not_avaliable!
            @available = false
          end

          def available? #: boolish
            @available
          end
        end

        # @rbs arguments: Hash[String, untyped]
        # @rbs return: String?
        def call(arguments)
          url = arguments['url']

          return 'Error: Please provide a URL parameter.' unless url

          url = normalize_url(url.to_s)
          return 'Error: Invalid URL format.' unless valid_url?(url)

          content = begin
            fetch_content(url)
          rescue StandardError => e
            raise FetchError, e.message
          end

          readable_content = extract_readable_content(content)

          if readable_content.strip.empty?
            "No readable content found on the page: #{url}"
          else
            "Content from #{url}:\n\n#{readable_content}"
          end
        rescue FetchError => e
          "Failed to fetch content from #{url}: #{e.message}"
        end

        private

        # @rbs url: String
        # @rbs return: String
        def normalize_url(url)
          url = url.strip
          url = "https://#{url}" unless url.match?(%r{\Ahttps?://})
          url
        end

        # @rbs url: String
        # @rbs return: bool
        def valid_url?(url)
          uri = URI.parse(url)
          return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          return false if uri.host.nil?

          true
        rescue URI::InvalidURIError
          false
        end

        # @rbs url: String
        # @rbs return: String
        def fetch_content(url)
          uri = URI.parse(url)
          host = uri.host
          port = uri.port
          raise 'Invalid URL: missing host' if host.nil?

          http = Net::HTTP.new(host, port)
          http.use_ssl = true if uri.scheme == 'https'
          http.open_timeout = 10
          http.read_timeout = 30

          path = uri.path
          path = '/' if path.nil? || path.empty?
          request = Net::HTTP::Get.new(path)
          request['User-Agent'] = 'Mozilla/5.0 (compatible; RubotyAI/1.0)'

          response = http.request(request)

          raise "HTTP error: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

          response.body
        end

        # @rbs content: String
        # @rbs return: String
        def extract_readable_content(content)
          document = Readability::Document.new(content)
          document.content
        end
      end
    end
  end
end

# Add Fetch tool only if ruby-readability is available
begin
  require 'ruby-readability'
  Ruboty::AiAgent::ToolDefinitions::Fetch.avaliable!
rescue LoadError
  # ruby-readability not available, skip Fetch tool
  Ruboty::AiAgent::ToolDefinitions::Fetch.not_avaliable!
end
