# frozen_string_literal: true

RSpec.describe Ruboty::AiAgent::Actions::ShowSystemPrompt do
  include DatabaseFactory

  let(:robot) { instance_double(Ruboty::Robot, brain:) }
  let(:brain) { create_brain(brain_data) }
  let(:message) do
    instance_double(Ruboty::Message, from_name: 'test_user', robot:).tap do |message|
      allow(message).to have_received(:reply)
    end
  end
  let(:action) { described_class.new(message) }
  let(:brain_data) { {} }

  describe '#call' do
    context 'when both prompts are set' do
      let(:brain_data) do
        {
          users: { 'test_user' => { system_prompt: 'User prompt' } },
          global_settings: { system_prompt: 'Global prompt' }
        }
      end

      it 'shows both prompts' do
        action.call
        expect(message).to have_received(:reply).with("User system prompt: User prompt\nGlobal system prompt: Global prompt")
      end
    end

    context 'when neither prompt is set' do
      it 'shows both as not set' do
        action.call
        expect(message).to have_received(:reply).with("User system prompt is not set.\nGlobal system prompt is not set.")
      end
    end

    context 'when only user prompt is set' do
      let(:brain_data) do
        { users: { 'test_user' => { system_prompt: 'User prompt' } } }
      end

      it 'shows user prompt and global as not set' do
        action.call
        expect(message).to have_received(:reply).with("User system prompt: User prompt\nGlobal system prompt is not set.")
      end
    end

    context 'when only global prompt is set' do
      let(:brain_data) do
        { global_settings: { system_prompt: 'Global prompt' } }
      end

      it 'shows user as not set and global prompt' do
        action.call
        expect(message).to have_received(:reply).with("User system prompt is not set.\nGlobal system prompt: Global prompt")
      end
    end
  end
end
