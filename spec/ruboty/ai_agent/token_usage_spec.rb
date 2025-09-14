# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::TokenUsage do
  describe '#initialize' do
    subject(:token_usage) do
      described_class.new(
        prompt_tokens: 50,
        completion_tokens: 20,
        total_tokens: 70,
        token_limit: 128_000
      )
    end

    it 'sets all attributes' do
      expect(token_usage.prompt_tokens).to eq(50)
      expect(token_usage.completion_tokens).to eq(20)
      expect(token_usage.total_tokens).to eq(70)
      expect(token_usage.token_limit).to eq(128_000)
    end
  end

  describe '#usage_percentage' do
    context 'with token limit' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 50,
          completion_tokens: 20,
          total_tokens: 70,
          token_limit: 128_000
        )
      end

      it 'calculates usage percentage' do
        expect(token_usage.usage_percentage).to eq(0.05)
      end
    end

    context 'without token limit' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 50,
          completion_tokens: 20,
          total_tokens: 70
        )
      end

      it 'returns nil' do
        expect(token_usage.usage_percentage).to be_nil
      end
    end

    context 'with high usage' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 90_000,
          completion_tokens: 10_000,
          total_tokens: 100_000,
          token_limit: 400_000
        )
      end

      it 'calculates correct percentage' do
        expect(token_usage.usage_percentage).to eq(25.0)
      end
    end
  end

  describe '#to_h' do
    subject(:token_usage) do
      described_class.new(
        prompt_tokens: 50,
        completion_tokens: 20,
        total_tokens: 70,
        token_limit: 128_000
      )
    end

    it 'returns hash with all attributes' do
      expect(token_usage.to_h).to include({
                                            prompt_tokens: 50,
                                            completion_tokens: 20,
                                            total_tokens: 70,
                                            token_limit: 128_000
                                          })
    end
  end

  describe '#over_auto_compact_threshold?' do
    context 'when usage percentage is above threshold' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 8500,
          completion_tokens: 1500,
          total_tokens: 10_000,
          token_limit: 12_000
        )
      end

      it 'returns true' do
        allow(ENV).to receive(:fetch).with('AUTO_COMPACT_THRESHOLD', 80).and_return('80')
        expect(token_usage.over_auto_compact_threshold?).to be true
      end
    end

    context 'when usage percentage is below threshold' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 7000,
          completion_tokens: 1000,
          total_tokens: 8000,
          token_limit: 12_000
        )
      end

      it 'returns false' do
        allow(ENV).to receive(:fetch).with('AUTO_COMPACT_THRESHOLD', 80).and_return('80')
        expect(token_usage.over_auto_compact_threshold?).to be false
      end
    end

    context 'when usage percentage is nil' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 50,
          completion_tokens: 20,
          total_tokens: 70
        )
      end

      it 'returns false' do
        expect(token_usage.over_auto_compact_threshold?).to be false
      end
    end

    context 'with custom threshold' do
      subject(:token_usage) do
        described_class.new(
          prompt_tokens: 7500,
          completion_tokens: 2500,
          total_tokens: 10_000,
          token_limit: 12_000
        )
      end

      it 'uses custom threshold' do
        allow(ENV).to receive(:fetch).with('AUTO_COMPACT_THRESHOLD', 80).and_return('90')
        expect(token_usage.over_auto_compact_threshold?).to be false
      end
    end
  end

  describe 'Recordable inclusion' do
    subject(:token_usage) do
      described_class.new(
        prompt_tokens: 50,
        completion_tokens: 20,
        total_tokens: 70
      )
    end

    it 'includes Recordable module' do
      expect(described_class.ancestors).to include(Ruboty::AiAgent::Recordable)
    end

    it 'responds to to_h from Recordable' do
      expect(token_usage).to respond_to(:to_h)
    end
  end
end
