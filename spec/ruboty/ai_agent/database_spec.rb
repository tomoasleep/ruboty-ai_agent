# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Database do
  include DatabaseFactory

  subject(:database) { create_database(brain_data) }

  let(:brain_data) { {} }

  describe '#data' do
    subject(:data) { database.data }

    let(:brain) do
      Ruboty::Brains::Memory.new.tap do |brain|
        brain.data.merge!(
          another_namespace: { key: 'value' },
          ai_agent: {
            user1: { name: 'Alice' }
          }
        )
      end
    end

    let(:database) { described_class.new(brain) }

    it 'returns existing data in the namespace' do
      expect(data).to eq({ user1: { name: 'Alice' } })
    end
  end

  describe '#user' do
    subject(:user_result) { database.user(user_id) }

    let(:user_id) { 'user123' }

    it 'returns a User instance' do
      expect(user_result).to be_a(Ruboty::AiAgent::User)
      expect(user_result.id).to eq(user_id)
      expect(user_result.database).to eq(database)
    end

    it 'calls User.find_or_create' do
      expect(Ruboty::AiAgent::User).to have_received(:find_or_create)
        .with(database: database, id: user_id)
        .and_return('user_instance')

      expect(user_result).to eq('user_instance')
    end
  end

  describe '#chat_thread' do
    subject(:thread_result) { database.chat_thread(thread_id) }

    let(:thread_id) { 'thread456' }

    it 'returns a ChatThread instance' do
      expect(thread_result).to be_a(Ruboty::AiAgent::ChatThread)
      expect(thread_result.id).to eq(thread_id)
      expect(thread_result.database).to eq(database)
    end

    it 'calls ChatThread.find_or_create' do
      expect(Ruboty::AiAgent::ChatThread).to have_received(:find_or_create)
        .with(database: database, id: thread_id)
        .and_return('thread_instance')

      expect(thread_result).to eq('thread_instance')
    end
  end
end
