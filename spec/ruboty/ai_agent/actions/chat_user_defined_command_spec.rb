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

  def register_command(name:, prompt:)
    robot.receive(body: "#{robot.name} add ai command /#{name} #{prompt}", from:, to:)
  end

  context 'when a user-defined command is defined' do
    let(:command_name) { 'greet' }
    let(:prompt) { 'Hello $1, welcome to $2!' }

    before do
      register_command(name: command_name, prompt:)

      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: 'Hello Bob, welcome to Ruboty!' }
        ],
        response_content: 'Hi!'
      )
    end

    context 'when using the defined command' do
      let(:body) { "/#{command_name} Bob Ruboty" }

      it 'processes the command and responds correctly' do
        receive_message
        expect(said_messages).to include(a_hash_including(body: 'Hi!'))
      end
    end
  end
end
