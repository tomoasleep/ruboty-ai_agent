# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::ChatThread do
  include DatabaseFactory

  subject(:chat_thread) { described_class.new(database: database, id: id) }

  let(:database) { create_database }
  let(:id) { 'thread_123' }

  describe '.find_or_create' do
    subject { described_class.find_or_create(database: database, id: id) }

    it 'creates a new ChatThread instance' do
      expect(subject).to be_a(described_class)
      expect(subject.database).to eq(database)
      expect(subject.id).to eq(id)
    end
  end

  describe '#initialize' do
    it 'sets database and id' do
      expect(chat_thread.database).to eq(database)
      expect(chat_thread.id).to eq(id)
    end
  end

  describe '#messages' do
    subject(:messages) { chat_thread.messages }

    let(:messages_instance) { instance_double('Ruboty::AiAgent::ChatThreadMessages') }

    before do
      allow(Ruboty::AiAgent::ChatThreadMessages).to receive(:new)
        .with(database: database, chat_thread_id: id)
        .and_return(messages_instance)
    end

    it 'returns a ChatThreadMessages instance' do
      expect(messages).to eq(messages_instance)
    end

    it 'memoizes the messages instance' do
      first_call = chat_thread.messages
      second_call = chat_thread.messages

      expect(first_call).to equal(second_call)
      expect(Ruboty::AiAgent::ChatThreadMessages).to have_received(:new).once
    end

    it 'passes correct parameters to ChatThreadMessages' do
      messages

      expect(Ruboty::AiAgent::ChatThreadMessages).to have_received(:new)
        .with(database: database, chat_thread_id: id)
    end
  end
end
