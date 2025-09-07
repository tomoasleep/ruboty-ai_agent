# frozen_string_literal: true

RSpec.describe Ruboty::AiAgent::GlobalSettings do
  include DatabaseFactory

  let(:database) { create_database }
  let(:global_settings) { described_class.find_or_create(database: database) }

  describe '#system_prompt' do
    context 'when system prompt is not set' do
      it 'returns nil' do
        expect(global_settings.system_prompt).to be_nil
      end
    end

    context 'when system prompt is set' do
      before do
        database.store('Test prompt', at: %i[global_settings system_prompt])
      end

      it 'returns the system prompt' do
        expect(global_settings.system_prompt).to eq('Test prompt')
      end
    end
  end

  describe '#system_prompt=' do
    it 'sets the system prompt' do
      global_settings.system_prompt = 'New prompt'
      expect(database.fetch(:global_settings, :system_prompt)).to eq('New prompt')
    end

    it 'can set to nil' do
      global_settings.system_prompt = nil
      expect(database.fetch(:global_settings, :system_prompt)).to be_nil
    end
  end
end
