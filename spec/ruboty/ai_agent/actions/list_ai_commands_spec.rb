# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::ListAiCommands do
  include RobotFactory

  subject(:call_robot) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

  let(:robot) { create_robot(env:) }
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
  let(:body) { 'list ai commands' }

  def said_messages
    robot.adapter.messages
  end

  describe 'when listing commands' do
    it 'replies with /clear command information' do
      call_robot

      expect(said_messages).to include(
        a_hash_including(
          body: a_string_matching(%r{/clear.*Clear the chat history}m)
        )
      )
    end

    context 'when a user-defined command is defined' do
      before do
        robot.receive(body: "#{robot.name} add ai command /test Some prompt", from:, to:)
      end

      it 'replies with /clear command information' do
        call_robot

        expect(said_messages).to include(
          a_hash_including(
            body: a_string_matching(%r{/test.*Some prompt}m)
          )
        )
      end
    end
  end
end
