# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::RemoveAiCommand do
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

  describe 'removing an existing command' do
    let(:body) { 'remove ai command /test' }

    before do
      robot.receive(body: "#{robot.name} add ai command /test Test prompt", from:, to:)
    end

    it 'removes the command successfully' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: "Command '/test' has been removed successfully!"
        )
      )
    end
  end

  describe 'removing a non-existent command' do
    let(:body) { 'remove ai command /nonexistent' }

    it 'returns an error message' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: "Command '/nonexistent' does not exist."
        )
      )
    end
  end
end
