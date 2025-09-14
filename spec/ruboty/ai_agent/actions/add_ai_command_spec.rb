# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::AddAiCommand do
  include RobotFactory

  subject(:call_robot) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

  let(:robot) { create_robot(env:) }
  let(:env) do
    {
      'OPENAI_API_KEY' => 'test_api_key',
      'OPENAI_MODEL' => 'gpt-5-nano'
    }
  end
  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }

  def said_messages
    robot.adapter.messages
  end

  describe 'adding a new command' do
    let(:body) { 'add ai command /test "This is a test prompt with $1 and $2"' }

    it 'creates a new command successfully' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: "Command '/test' has been added successfully!"
        )
      )
    end
  end

  describe 'adding an existing command' do
    let(:body) { 'add ai command /test "This is a test prompt"' }

    before do
      robot.receive(body: "#{robot.name} add ai command /test Some prompt", from:, to:)
    end

    it 'returns an error message' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: "Command '/test' already exists. Use a different name or remove the existing command first."
        )
      )
    end
  end
end
