# frozen_string_literal: true

RSpec.describe Ruboty::AiAgent::Actions::ShowSystemPrompt do
  include RobotFactory

  subject(:call_robot) { robot.receive(body: "#{robot.name} show system prompt", from:, to:) }

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

  def said_messages
    robot.adapter.messages
  end

  describe 'when showing system prompt' do
    context 'when both prompts are set' do
      before do
        database.user(from).system_prompt = 'User prompt'
        database.global_settings.system_prompt = 'Global prompt'
      end

      it 'shows both prompts' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: "User system prompt: User prompt\nGlobal system prompt: Global prompt"))
      end
    end

    context 'when neither prompt is set' do
      it 'shows both as not set' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: "User system prompt is not set.\nGlobal system prompt is not set."))
      end
    end

    context 'when only user prompt is set' do
      before do
        database.user(from).system_prompt = 'User prompt'
      end

      it 'shows user prompt and global as not set' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: "User system prompt: User prompt\nGlobal system prompt is not set."))
      end
    end

    context 'when only global prompt is set' do
      before do
        database.global_settings.system_prompt = 'Global prompt'
      end

      it 'shows user as not set and global prompt' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: "User system prompt is not set.\nGlobal system prompt: Global prompt"))
      end
    end
  end
end
