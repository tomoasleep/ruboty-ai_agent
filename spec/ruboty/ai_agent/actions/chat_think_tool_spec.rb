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
  let(:body) { 'What is the answer to 1+1?' }

  def said_messages #: Array[Hash[untyped, untyped]]
    robot.adapter.messages
  end

  context 'when think tool is called' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

    before do
      # Mock MCP HTTP calls
      stub_mcp_initialize(
        base_url: 'http://localhost:3000'
      )

      # First API call - returns tool call
      stub_openai_chat_completion_with_tool_call(
        messages: [
          { role: 'user', content: body }
        ],
        tool_name: 'think',
        tool_arguments: { thought: 'I have completely understood.' },
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
                  name: 'think',
                  arguments: '{"thought":"I have completely understood."}'
                }
              }
            ]
          },
          { role: 'tool', tool_call_id: 'call_123', content: 'I have completely understood.' }
        ],
        response_content: 'The answer is 11.'
      )
    end

    it 'says thought' do
      receive_message

      expect(said_messages).to match([
                                       a_hash_including(body: "Thought:\nI have completely understood."),
                                       a_hash_including(body: 'The answer is 11.')
                                     ])
    end
  end
end
