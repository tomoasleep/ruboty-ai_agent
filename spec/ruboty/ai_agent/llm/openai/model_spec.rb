# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::LLM::OpenAI::Model do
  describe '#initialize' do
    subject(:model) { described_class.new(model_name) }
    let(:model_name) { 'gpt-4' }

    it 'sets the model name' do
      expect(model.name).to eq(model_name)
    end
  end

  describe '#token_limit' do
    subject(:token_limit) { described_class.new(model_name).token_limit }

    context 'when model name contains gpt-5' do
      let(:model_name) { 'gpt-5' }

      it 'returns 400,000 tokens' do
        expect(token_limit).to eq(400_000)
      end
    end

    context 'when model name contains gpt-5 with variations' do
      ['gpt-5-turbo', 'gpt-5-nano', 'some-gpt-5-model'].each do |name|
        context "with model name '#{name}'" do
          let(:model_name) { name }

          it 'returns 400,000 tokens' do
            expect(token_limit).to eq(400_000)
          end
        end
      end
    end

    context 'when model name does not contain gpt-5' do
      ['gpt-4', 'gpt-3.5-turbo', 'claude-3', 'other-model'].each do |name|
        context "with model name '#{name}'" do
          let(:model_name) { name }

          it 'returns 128,000 tokens' do
            expect(token_limit).to eq(128_000)
          end
        end
      end
    end
  end
end
