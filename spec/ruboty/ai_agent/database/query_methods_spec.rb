# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Database::QueryMethods do
  include DatabaseFactory

  subject(:database) { create_database(brain_data) }

  let(:brain_data) { {} }

  describe '#fetch' do
    subject(:fetch_result) { database.fetch(*keys) }

    let(:brain_data) do
      {
        users: {
          'user1' => { name: 'Alice', age: 30 },
          'user2' => { name: 'Bob', age: 25 }
        },
        settings: {
          theme: 'dark',
          notifications: true
        }
      }
    end

    context 'fetching nested user data' do
      let(:keys) { [:users, 'user1', :name] }
      it { is_expected.to eq('Alice') }
    end

    context 'fetching settings' do
      let(:keys) { %i[settings theme] }
      it { is_expected.to eq('dark') }
    end

    context 'fetching non-existent user' do
      let(:keys) { [:users, 'user3'] }
      it { is_expected.to be_nil }
    end

    context 'fetching non-existent key' do
      let(:keys) { [:non_existent] }
      it { is_expected.to be_nil }
    end

    context 'with Recordable objects' do
      let(:keys) { [:users, 'user1'] }

      before do
        allow(Ruboty::AiAgent::Recordable).to receive(:convert_recursively).and_return('converted_value')
      end

      it 'converts results using Recordable' do
        expect(fetch_result).to eq('converted_value')
      end
    end
  end

  describe '#delete' do
    subject(:delete_item) { database.delete(*keys) }

    let(:brain_data) do
      {
        users: {
          'user1' => { name: 'Alice' },
          'user2' => { name: 'Bob' }
        },
        items: %w[item1 item2 item3]
      }
    end

    context 'deleting from hash' do
      let(:keys) { [:users, 'user1'] }

      it 'deletes the specified key' do
        delete_item
        expect(database.fetch(:users)).to eq({ 'user2' => { name: 'Bob' } })
      end
    end

    context 'deleting from array' do
      let(:keys) { [:items, 1] }

      it 'deletes item at specified index' do
        delete_item
        expect(database.fetch(:items)).to eq(%w[item1 item3])
      end
    end

    context 'deleting with out of bounds index' do
      let(:keys) { [:items, 10] }

      it 'does nothing for out of bounds index' do
        delete_item
        expect(database.fetch(:items)).to eq(%w[item1 item2 item3])
      end
    end
  end

  describe '#keys' do
    subject(:keys_result) { database.keys(*keys) }

    let(:brain_data) do
      {
        users: {
          'user1' => {},
          'user2' => {},
          'user3' => {}
        },
        items: %w[a b c]
      }
    end

    context 'getting hash keys' do
      let(:keys) { [:users] }
      it { is_expected.to contain_exactly('user1', 'user2', 'user3') }
    end

    context 'getting array indices' do
      let(:keys) { [:items] }
      it { is_expected.to eq([0, 1, 2]) }
    end

    context 'getting top-level keys' do
      let(:keys) { [] }
      it { is_expected.to contain_exactly(:users, :items) }
    end

    context 'getting keys for non-existent path' do
      let(:keys) { [:non_existent] }
      it { is_expected.to eq([]) }
    end
  end

  describe '#key?' do
    subject(:key_exists) { database.key?(*keys) }

    let(:brain_data) do
      {
        users: {
          'user1' => { name: 'Alice' }
        }
      }
    end

    context 'checking existing key' do
      let(:keys) { [:users] }
      it { is_expected.to be true }
    end

    context 'checking nested existing key' do
      let(:keys) { [:users, 'user1'] }
      it { is_expected.to be true }
    end

    context 'checking non-existent key' do
      let(:keys) { [:non_existent] }
      it { is_expected.to be false }
    end

    context 'checking non-existent nested key' do
      let(:keys) { [:users, 'user2'] }
      it { is_expected.to be false }
    end
  end

  describe '#store' do
    subject(:store_value) { database.store(value, at: at) }

    let(:value) { { name: 'Charlie', age: 35 } }
    let(:at) { [:users, 'user3'] }

    it 'stores value at specified path' do
      store_value
      expect(database.fetch(:users, 'user3')).to eq(value)
    end

    context 'creating nested structure' do
      let(:value) { { enabled: true } }
      let(:at) { %i[deeply nested config] }

      it 'creates nested structure if needed' do
        store_value
        expect(database.fetch(:deeply, :nested, :config)).to eq(value)
      end
    end

    context 'with object that responds to to_h' do
      let(:object) { double('Object', to_h: { converted: 'data' }) }

      it 'calls to_h on the value' do
        database.store(object, at: [:test])
        expect(database.fetch(:test)).to eq({ converted: 'data' })
      end
    end
  end

  describe '#len' do
    subject(:length_result) { database.len(*keys) }

    let(:brain_data) do
      {
        users: %w[user1 user2 user3],
        config: { a: 1, b: 2 }
      }
    end

    context 'getting length of arrays' do
      let(:keys) { [:users] }
      it { is_expected.to eq(3) }
    end

    context 'getting length of hashes' do
      let(:keys) { [:config] }
      it { is_expected.to eq(2) }
    end

    context 'getting length for non-existent paths' do
      let(:keys) { [:non_existent] }
      it { is_expected.to eq(0) }
    end
  end
end
