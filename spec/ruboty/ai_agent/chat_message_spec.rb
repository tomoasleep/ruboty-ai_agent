# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::ChatMessage do
  describe '#to_h' do
    subject(:to_h) { message.to_h }

    context 'with minimal attributes' do
      let(:message) { described_class.new(role: :system, content: 'You are helpful') }

      it 'returns hash with all attributes' do
        expect(to_h).to include({
                                  role: :system,
                                  content: 'You are helpful',
                                  tool_call_id: nil,
                                  tool_name: nil,
                                  tool_arguments: nil,
                                  token_usage: nil,
                                  token_limit: nil
                                })
      end
    end

    context 'with all attributes' do
      let(:message) do
        described_class.new(
          role: :tool,
          content: '4',
          tool_call_id: 'call_456',
          tool_name: 'calculator',
          tool_arguments: { expression: '2+2' },
          token_usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
          token_limit: 128_000
        )
      end

      it 'returns hash with all attributes' do
        expect(to_h).to include({
                                  role: :tool,
                                  content: '4',
                                  tool_call_id: 'call_456',
                                  tool_name: 'calculator',
                                  tool_arguments: { expression: '2+2' },
                                  token_usage: { prompt_tokens: 10, completion_tokens: 5, total_tokens: 15 },
                                  token_limit: 128_000
                                })
      end
    end
  end

  describe '.from_llm_response' do
    subject(:message) do
      described_class.from_llm_response(
        tool: tool,
        tool_call_id: tool_call_id,
        tool_arguments: tool_arguments,
        tool_response: tool_response
      )
    end

    let(:tool) { instance_double('Ruboty::AiAgent::Tool', name: 'weather') }
    let(:tool_call_id) { 'call_789' }
    let(:tool_arguments) { { location: 'Tokyo' } }
    let(:tool_response) { 'Sunny, 25°C' }

    it 'creates a tool message' do
      aggregate_failures do
        expect(message.role).to eq(:tool)
        expect(message.content).to eq('Sunny, 25°C')
        expect(message.tool_name).to eq('weather')
        expect(message.tool_call_id).to eq('call_789')
        expect(message.tool_arguments).to eq({ location: 'Tokyo' })
      end
    end
  end

  describe 'Recordable inclusion' do
    subject(:message) { described_class.new(role: :user, content: 'Test') }

    it 'includes Recordable module' do
      expect(described_class.ancestors).to include(Ruboty::AiAgent::Recordable)
    end

    it 'responds to to_h from Recordable' do
      expect(message).to respond_to(:to_h)
    end
  end

  describe 'various role types' do
    %i[system user assistant tool].each do |role|
      context "with role :#{role}" do
        subject(:message) { described_class.new(role: role, content: "#{role} message") }

        it "accepts :#{role} as valid role" do
          expect(message.role).to eq(role)
          expect(message.content).to eq("#{role} message")
        end
      end
    end
  end

  describe 'token usage and limit' do
    context 'with token usage and limit' do
      let(:token_usage) { { prompt_tokens: 50, completion_tokens: 20, total_tokens: 70 } }
      let(:token_limit) { 128_000 }
      let(:message) { described_class.new(role: :assistant, content: 'Hello', token_usage: token_usage, token_limit: token_limit) }

      it 'stores and retrieves token usage' do
        expect(message.token_usage).to eq(token_usage)
      end

      it 'stores and retrieves token limit' do
        expect(message.token_limit).to eq(token_limit)
      end
    end

    context 'without token usage and limit' do
      let(:message) { described_class.new(role: :user, content: 'Hi') }

      it 'returns nil for token usage' do
        expect(message.token_usage).to be_nil
      end

      it 'returns nil for token limit' do
        expect(message.token_limit).to be_nil
      end
    end
  end
end
