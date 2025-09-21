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
  let(:body) { 'Do you have ping command?' }

  def said_messages #: Array[Hash[untyped, untyped]]
    robot.adapter.messages
  end

  context 'when bot_help tool is called' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

    before do
      # First API call - returns tool call
      stub_openai_chat_completion_with_tool_call(
        messages: [
          { role: 'user', content: body }
        ],
        tool_name: 'bot_help',
        tool_arguments: {},
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
                  name: 'bot_help',
                  arguments: '{}'
                }
              }
            ]
          },
          { role: 'tool', tool_call_id: 'call_123', content: include('Return PONG to PING') }
        ],
        response_content: 'Yes.'
      )
    end

    it 'looks up help' do
      receive_message

      expect(said_messages).to match([
                                       a_hash_including(body: '> Calling tool bot_help with arguments {}'),
                                       a_hash_including(body: start_with('> Tool response: ruboty')),
                                       a_hash_including(body: 'Yes.')
                                     ])
    end
  end
end
