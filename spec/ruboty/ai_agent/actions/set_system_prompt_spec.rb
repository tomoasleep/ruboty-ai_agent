# frozen_string_literal: true

RSpec.describe Ruboty::AiAgent::Actions::SetSystemPrompt do
  include OpenAIMockHelper
  include RobotFactory

  subject(:call_robot) { robot.receive(body: full_body, from:, to:) }

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
  let(:full_body) { "#{robot.name} set #{scope_str}system prompt \"#{prompt}\"" }
  let(:scope_str) { scope ? "#{scope} " : '' }
  let(:prompt) { 'Test prompt' }

  def said_messages
    robot.adapter.messages
  end

  describe 'when setting system prompt' do
    context 'with user scope (default)' do
      let(:scope) { nil }

      it 'sets user system prompt' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: 'Set user system prompt: Test prompt'))
      end

      it 'stores the prompt in user data' do
        call_robot
        expect(database.data.dig(:users, from, :system_prompt)).to eq('Test prompt')
      end
    end

    context 'with explicit user scope' do
      let(:scope) { 'user' }

      it 'sets user system prompt' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: 'Set user system prompt: Test prompt'))
      end
    end

    context 'with global scope' do
      let(:scope) { 'global' }

      it 'sets global system prompt' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: 'Set global system prompt: Test prompt'))
      end

      it 'stores the prompt in global data' do
        call_robot
        expect(database.data.dig(:global_settings, :system_prompt)).to eq('Test prompt')
      end
    end

    context 'with invalid scope' do
      let(:scope) { 'invalid' }

      before do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: 'set invalid system prompt "Test prompt"' }
          ],
          response_content: 'Use /user or /global to specify the scope.'
        )
      end

      it 'returns error message' do
        call_robot
        expect(said_messages).to include(a_hash_including(body: 'Use /user or /global to specify the scope.'))
      end
    end
  end
end
