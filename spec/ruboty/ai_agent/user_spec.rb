# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::User do
  include DatabaseFactory

  subject(:user) { described_class.new(database: database, id: id) }

  let(:database) { create_database }
  let(:id) { 'user123' }

  describe '.find_or_create' do
    subject { described_class.find_or_create(database: database, id: id) }

    it 'creates a new User instance' do
      expect(user).to be_a(described_class)
      expect(user.database).to eq(database)
      expect(user.id).to eq(id)
    end
  end

  describe '#initialize' do
    it 'sets database and id' do
      expect(user.database).to eq(database)
      expect(user.id).to eq(id)
    end
  end

  describe '#mcp_configurations' do
    subject(:mcp_configurations) { user.mcp_configurations }

    let(:mcp_configurations_instance) { instance_double(Ruboty::AiAgent::UserMcpConfigurations) }

    before do
      allow(Ruboty::AiAgent::UserMcpConfigurations).to receive(:new)
        .with(database: database, user_id: id)
        .and_return(mcp_configurations_instance)
    end

    it 'returns a UserMcpConfigurations instance' do
      expect(mcp_configurations).to eq(mcp_configurations_instance)
    end

    it 'memoizes the mcp_configurations instance' do
      first_call = user.mcp_configurations
      second_call = user.mcp_configurations

      expect(first_call).to equal(second_call)
      expect(Ruboty::AiAgent::UserMcpConfigurations).to have_received(:new).once
    end

    it 'passes correct parameters to UserMcpConfigurations' do
      mcp_configurations

      expect(Ruboty::AiAgent::UserMcpConfigurations).to have_received(:new)
        .with(database: database, user_id: id)
    end
  end

  describe '#ai_memories' do
    subject(:ai_memories) { user.ai_memories }

    let(:ai_memories_instance) { instance_double(Ruboty::AiAgent::UserAiMemories) }

    before do
      allow(Ruboty::AiAgent::UserAiMemories).to receive(:new)
        .with(database: database, user_id: id)
        .and_return(ai_memories_instance)
    end

    it 'returns a UserAiMemories instance' do
      expect(ai_memories).to eq(ai_memories_instance)
    end

    it 'memoizes the ai_memories instance' do
      first_call = user.ai_memories
      second_call = user.ai_memories

      expect(first_call).to equal(second_call)
      expect(Ruboty::AiAgent::UserAiMemories).to have_received(:new).once
    end

    it 'passes correct parameters to UserAiMemories' do
      ai_memories

      expect(Ruboty::AiAgent::UserAiMemories).to have_received(:new)
        .with(database: database, user_id: id)
    end
  end

  describe 'attribute readers' do
    it 'provides read access to database' do
      expect(user.database).to eq(database)
    end

    it 'provides read access to id' do
      expect(user.id).to eq(id)
    end
  end
end
