# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  include OpenAIMockHelper
  include McpMockHelper

  subject(:action) { described_class.new(message) }

  let(:robot) { Ruboty::Robot.new }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'Hello, AI!' }

  let(:original_message) do
    Ruboty::Message.new(
      body: body,
      from: from,
      to: to,
      robot: robot
    )
  end

  let(:message) do
    # Actions::Chat expects a message with reply method and [] accessor
    message = original_message
    allow(message).to receive(:reply)
    allow(message).to receive(:[]).with(:body).and_return(body)
    message
  end

  before do
    # Stub ENV variables
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_api_key')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-5-nano').and_return('gpt-5')
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('DEBUG').and_return(nil)
    allow(ENV).to receive(:[]).with('OPENAI_ORG_ID').and_return(nil)

    # Allow action to use real database
    allow(action).to receive(:database).and_return(database)
    allow(action).to receive(:robot).and_return(robot)
  end

  describe '#call' do
    subject(:call_action) { action.call }

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
        call_action
        expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
      end

      it 'adds assistant response to chat thread' do
        call_action
        expect(messages.any? { |m| m.role == :assistant && m.content == 'Hello! How can I help you today?' }).to be true
      end

      it 'replies with assistant message' do
        expect(message).to receive(:reply).with('Hello! How can I help you today?')
        call_action
      end

      describe 'conversation history preservation' do
        subject(:second_call) do
          action.call
          allow(message).to receive(:[]).with(:body).and_return(second_body)

          # Setup second API call stub
          stub_openai_chat_completion_with_content(
            messages: [
              { role: 'user', content: body },
              { role: 'assistant', content: 'Hello! How can I help you today?' },
              { role: 'user', content: second_body }
            ],
            response_content: 'I cannot check the weather in real-time.'
          )

          action.call
        end

        let(:second_body) { 'What is the weather?' }

        it 'preserves all messages in order' do
          second_call

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
            transport: 'http',
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
        expect(message).to receive(:reply).with(
          'Calling tool calculator with arguments {expression: "21 * 2"}',
          streaming: true
        )
        expect(message).to receive(:reply).with('Tool response: ["42"]')
        expect(message).to receive(:reply).with('The answer is 42.')

        call_action
      end

      it 'adds tool messages to chat thread' do
        call_action

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
        call_action
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
        expect(message).to receive(:reply).with(/エラーが発生しました/)
        call_action
      end
    end
  end

  describe '#body_param' do
    subject { action.body_param }

    it { is_expected.to eq(body) }
  end
end
