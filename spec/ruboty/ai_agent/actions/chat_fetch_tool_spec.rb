# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  include OpenAIMockHelper
  include McpMockHelper
  include RobotFactory

  subject(:receive_message) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

  let(:action) { described_class.new(message) }

  let(:robot) { create_robot(env:) }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }
  let(:env) do
    {
      'OPENAI_API_KEY' => 'test_api_key',
      'OPENAI_MODEL' => 'gpt-5-nano'
    }
  end

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'fetch https://example.com' }

  def said_messages #: Array[Hash[untyped, untyped]]
    robot.adapter.messages
  end

  context 'when fetch tool is called' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

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

      # First API call - returns tool call
      stub_openai_chat_completion_with_tool_call(
        messages: [
          { role: 'user', content: body }
        ],
        tool_name: 'fetch',
        tool_arguments: { url: 'https://example.com' },
        tool_call_id: 'call_123'
      )

      # Second API call - after tool execution
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body },
          {
            role: 'assistant',
            content: '',
            tool_calls: [
              {
                id: 'call_123',
                type: 'function',
                function: {
                  name: 'fetch',
                  arguments: '{"url":"https://example.com"}'
                }
              }
            ]
          },
          { role: 'tool', tool_call_id: 'call_123', content: include('Main Title') }
        ],
        response_content: 'Fetched content.'
      )
    end

    it 'says tool call' do
      receive_message

      expect(said_messages).to match([
                                       a_hash_including(body: '> Calling tool fetch with arguments {"url":"https://example.com"}'),
                                       a_hash_including(body: start_with('> Tool response:')),
                                       a_hash_including(body: 'Fetched content.')
                                     ])
    end
  end
end
