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
      'OPENAI_MODEL' => 'gpt-5-nano',
      'DEBUG' => nil,
      'OPENAI_ORG_ID' => nil
    }
  end

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'Hello, AI!' }

  def said_messages #: Array[Hash[untyped, untyped]]
    robot.adapter.messages
  end

  context 'when chat completes successfully' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

    before do
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body }
        ],
        response_content: 'Hello! How can I help you today?'
      )
    end

    it 'adds user message to chat thread' do
      receive_message
      expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
    end

    it 'adds assistant response to chat thread' do
      receive_message
      expect(messages.any? { |m| m.role == :assistant && m.content == 'Hello! How can I help you today?' }).to be true
    end

    it 'replies with assistant message' do
      receive_message
      expect(said_messages).to include(a_hash_including(body: 'Hello! How can I help you today?'))
    end

    describe 'conversation history preservation' do
      subject(:receive_message_second) do
        # Setup second API call stub
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: body },
            { role: 'assistant', content: 'Hello! How can I help you today?' },
            { role: 'user', content: second_body }
          ],
          response_content: 'I cannot check the weather in real-time.'
        )

        robot.receive(from:, to:, body: "#{robot.name} #{second_body}")
      end

      let(:second_body) { 'What is the weather?' }

      it 'preserves all messages in order' do
        receive_message
        receive_message_second

        expect(messages.length).to eq(4)
        expect(messages[0]).to have_attributes(role: :user, content: body)
        expect(messages[1]).to have_attributes(role: :assistant)
        expect(messages[2]).to have_attributes(role: :user, content: second_body)
        expect(messages[3]).to have_attributes(role: :assistant)
      end
    end
  end

  context 'when tool is called' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

    let(:tool) do
      Ruboty::AiAgent::Tool.new(
        name: 'calculator',
        title: 'Calculator',
        description: 'Performs calculations',
        input_schema: {}
      ) { |_args| '42' }
    end

    before do
      # Configure user with MCP that provides the tool
      user = database.user(from)
      user.mcp_configurations.add(
        Ruboty::AiAgent::McpConfiguration.new(
          name: 'calc_server',
          transport: :http,
          headers: {},
          url: 'http://localhost:3000'
        )
      )

      # Mock MCP HTTP calls
      stub_mcp_initialize(
        base_url: 'http://localhost:3000'
      )

      stub_mcp_list_tools(
        base_url: 'http://localhost:3000',
        tools: [
          {
            'name' => 'calculator',
            'description' => 'Performs calculations',
            'inputSchema' => {}
          }
        ]
      )

      stub_mcp_call_tool(
        base_url: 'http://localhost:3000',
        tool_name: 'calculator',
        tool_arguments: { expression: '21 * 2' },
        response_content: '42'
      )

      # First API call - returns tool call
      stub_openai_chat_completion_with_tool_call(
        messages: [
          { role: 'user', content: body }
        ],
        tools: [
          {
            type: 'function',
            function: {
              name: 'calculator',
              description: 'Performs calculations',
              parameters: {}
            }
          }
        ],
        tool_name: 'calculator',
        tool_arguments: { expression: '21 * 2' },
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
                  name: 'calculator',
                  arguments: '{"expression":"21 * 2"}'
                }
              }
            ]
          },
          { role: 'tool', tool_call_id: 'call_123', content: '["42"]' }
        ],
        tools: [
          {
            type: 'function',
            function: {
              name: 'calculator',
              description: 'Performs calculations',
              parameters: {}
            }
          }
        ],
        response_content: 'The answer is 42.'
      )
    end

    it 'notifies about tool call' do
      receive_message

      expect(said_messages).to include(a_hash_including(body: 'Calling tool calculator with arguments {expression: "21 * 2"}'))
      expect(said_messages).to include(a_hash_including(body: 'Tool response: ["42"]'))
      expect(said_messages).to include(a_hash_including(body: 'The answer is 42.'))
    end

    it 'adds tool messages to chat thread' do
      receive_message

      aggregate_failures do
        expect(messages.any? { |m| m.role == :user }).to be true
        expect(messages.any? { |m| m.role == :assistant && m.tool_name == 'calculator' }).to be true
        expect(messages.any? { |m| m.role == :tool }).to be true
        expect(messages.any? { |m| m.role == :assistant && m.content == 'The answer is 42.' }).to be true
      end
    end
  end

  context 'when user is not specified' do
    let(:from) { nil }
    let(:chat_thread) { database.chat_thread('default') }
    let(:messages) { chat_thread.messages.all_values }

    before do
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body }
        ],
        response_content: 'Hello! How can I help you today?'
      )
    end

    it 'uses default as user identifier' do
      receive_message
      expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
    end
  end

  context 'when an error occurs' do
    before do
      # Stub the API to return an error
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 500, body: 'Internal Server Error')
    end

    it 'replies with error message' do
      receive_message

      expect(said_messages).to include(a_hash_including(body: /エラーが発生しました/))
    end
  end
end
