# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::CachedValue do
  subject(:cache) do
    described_class.new(
      data: data,
      expires_at: expires_at
    )
  end

  let(:data) { [{ 'name' => 'get_weather', 'description' => 'Get weather info' }] }
  let(:expires_at) { Time.now + 600 }

  describe '#initialize' do
    it 'sets all attributes correctly' do
      expect(cache.data).to eq(data)
      expect(cache.expires_at).to eq(expires_at.round)
    end
  end

  describe '#expired?' do
    context 'when cache is not expired' do
      it { is_expected.not_to be_expired }
    end

    context 'when cache is expired' do
      let(:expires_at) { Time.now - 1 }

      it { is_expected.to be_expired }
    end
  end

  describe '#valid?' do
    context 'when cache is valid' do
      it { is_expected.to be_valid }
    end

    context 'when cache is invalid' do
      let(:expires_at) { Time.now - 1 }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#to_h' do
    subject(:to_h_result) { cache.to_h }

    it 'converts to hash with correct keys' do
      expect(to_h_result).to include(
        data: data
      )
      expect(Time.parse(to_h_result[:expires_at])).to eq(cache.expires_at.round)
    end
  end
end
