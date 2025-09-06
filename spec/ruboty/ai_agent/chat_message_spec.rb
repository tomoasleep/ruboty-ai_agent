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
                                  tool_arguments: nil
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
          tool_arguments: { expression: '2+2' }
        )
      end

      it 'returns hash with all attributes' do
        expect(to_h).to include({
                                  role: :tool,
                                  content: '4',
                                  tool_call_id: 'call_456',
                                  tool_name: 'calculator',
                                  tool_arguments: { expression: '2+2' }
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
end
