# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::ToolDefinitions::Fetch do
  include RequestFactory

  let(:robot) { create_robot }
  let(:request) { create_request(robot:, message: { body: }) }
  let(:fetch_tool) { described_class.new(request:) }

  let(:body) { 'Fetch tool test' }

  describe '#call' do
    context 'when content is available' do
      let(:html_content) do
        <<~HTML
          <html>
            <head><title>Test Page</title></head>
            <body>
              <div class="content">
                <h1>Main Title</h1>
                <p>This is the main content of the page.</p>
              </div>
            </body>
          </html>
        HTML
      end

      before do
        stub_request(:get, 'https://example.com/')
          .to_return(status: 200, body: html_content, headers: { 'Content-Type' => 'text/html' })
      end

      it 'fetches and extracts readable content' do
        result = fetch_tool.call({ 'url' => 'https://example.com' })

        expect(result).to include('Content from https://example.com:')
        expect(result).to include('Main Title')
        expect(result).to include('This is the main content of the page.')
      end

      context 'when URL is provided without protocol' do
        before do
          stub_request(:get, 'https://example.com/')
            .to_return(status: 200, body: html_content, headers: { 'Content-Type' => 'text/html' })
        end

        it 'normalizes URL to https' do
          fetch_tool.call({ 'url' => 'example.com' })

          expect(a_request(:get, 'https://example.com/')).to have_been_made
        end
      end
    end

    context 'when HTTP request fails' do
      before do
        stub_request(:get, 'https://example.com/')
          .to_return(status: 404, body: 'Not Found')
      end

      it 'returns error message' do
        result = fetch_tool.call({ 'url' => 'https://example.com' })

        expect(result).to include('Failed to fetch content')
        expect(result).to include('HTTP error: 404')
      end
    end

    context 'when no URL is provided' do
      it 'returns error message' do
        result = fetch_tool.call({})

        expect(result).to include('Error: Please provide a URL parameter')
      end
    end
  end
end
