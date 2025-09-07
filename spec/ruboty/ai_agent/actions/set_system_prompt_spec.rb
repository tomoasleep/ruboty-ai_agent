# frozen_string_literal: true

RSpec.describe Ruboty::AiAgent::Actions::SetSystemPrompt do
  include DatabaseFactory

  let(:robot) { instance_double('Ruboty::Robot', brain:) }
  let(:brain) { create_brain }
  let(:message) do
    instance_double('Ruboty::Message', from_name: 'test_user', robot:).tap do |message|
      allow(message).to receive(:[]).with(:scope).and_return(scope)
      allow(message).to receive(:[]).with(:prompt).and_return('Test prompt')
      allow(message).to receive(:reply)
    end
  end
  let(:action) { described_class.new(message) }

  describe '#call' do
    context 'with user scope (default)' do
      let(:scope) { nil }

      it 'sets user system prompt' do
        action.call
        expect(message).to have_received(:reply).with('Set user system prompt: Test prompt')
      end

      it 'stores the prompt in user data' do
        action.call
        expect(action.database.data.dig(:users, 'test_user', :system_prompt)).to eq('Test prompt')
      end
    end

    context 'with explicit user scope' do
      let(:scope) { 'user' }

      it 'sets user system prompt' do
        action.call
        expect(message).to have_received(:reply).with('Set user system prompt: Test prompt')
      end
    end

    context 'with global scope' do
      let(:scope) { 'global' }

      it 'sets global system prompt' do
        action.call
        expect(message).to have_received(:reply).with('Set global system prompt: Test prompt')
      end

      it 'stores the prompt in global data' do
        action.call
        expect(action.database.data.dig(:global_settings, :system_prompt)).to eq('Test prompt')
      end
    end

    context 'with invalid scope' do
      let(:scope) { 'invalid' }

      it 'returns error message' do
        action.call
        expect(message).to have_received(:reply).with("Error: Invalid scope 'invalid'. Use 'user' or 'global'.")
      end
    end
  end
end
