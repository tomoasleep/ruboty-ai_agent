# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Ruboty::AiAgent::Agent do
  include UserFactory

  subject(:agent) do
    described_class.new(
      llm: llm,
      messages: messages,
      tools: tools
    )
  end

  let(:llm) { instance_double(Ruboty::AiAgent::LLM::OpenAI) }
  let(:messages) { [] }
  let(:tools) { [] }

  describe '#initialize' do
    describe '#llm' do
      subject { agent.llm }

      it { is_expected.to eq(llm) }
    end

    describe '#messages' do
      subject { agent.messages }

      it { is_expected.to eq(messages) }
    end

    describe '#tools' do
      subject { agent.tools }

      it { is_expected.to eq(tools) }
    end

    context 'with provided messages and tools' do
      let(:messages) do
        [
          Ruboty::AiAgent::ChatMessage.new(role: :system, content: 'You are a helpful assistant'),
          Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello')
        ]
      end

      let(:tools) do
        [
          create_tool(name: 'test_tool')
        ]
      end

      describe '#messages' do
        subject { agent.messages }

        it { is_expected.to eq(messages) }
      end

      describe '#tools' do
        subject { agent.tools }

        it { is_expected.to eq(tools) }
      end
    end
  end

  describe '#complete' do
    subject(:complete_response) { agent.complete }

    let(:llm_response) { instance_double(Ruboty::AiAgent::LLM::Response) }
    let(:response_message) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Test response') }

    before do
      allow(llm).to receive(:complete).and_return(llm_response)
      allow(llm_response).to receive_messages(message: response_message, tool: nil)
    end

    describe 'LLM interaction' do
      it 'calls LLM complete with messages and tools' do
        complete_response

        expect(llm).to have_received(:complete).with(
          messages: agent.messages,
          tools: agent.tools
        )
      end
    end

    describe 'response handling' do
      it { is_expected.to eq(llm_response) }
    end

    describe 'message history after complete' do
      let!(:initial_message_count) { agent.messages.count }

      before { complete_response }

      it 'adds response message to history' do
        expect(agent.messages.count).to eq(initial_message_count + 1)
        expect(agent.messages.last).to eq(response_message)
      end
    end

    context 'with tool call response' do
      let(:tool) { create_tool(name: 'test_tool') }
      let(:tool_call_id) { 'call_123' }
      let(:tool_arguments) { { test: 'value' } }
      let(:tool_response) { 'tool result' }
      let(:tool_message) do
        Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: nil, tool_call_id: tool_call_id)
      end
      let(:tool_response_message) { Ruboty::AiAgent::ChatMessage.new(role: :tool, content: tool_response) }

      let(:second_response) { instance_double(Ruboty::AiAgent::LLM::Response) }

      before do
        allow(llm_response).to receive_messages(tool: tool, tool_call_id: tool_call_id, tool_arguments: tool_arguments, call_tool: tool_response, message: tool_message)

        allow(Ruboty::AiAgent::ChatMessage).to receive(:from_llm_response)
          .with(
            tool: tool,
            tool_call_id: tool_call_id,
            tool_arguments: tool_arguments,
            tool_response: tool_response
          )
          .and_return(tool_response_message)

        # Setup second LLM call after tool execution
        allow(second_response).to receive_messages(message: response_message, tool: nil)
        allow(llm).to receive(:complete).and_return(llm_response, second_response)
      end

      it 'handles tool call and returns final response' do
        expect(complete_response).to eq(second_response)
      end
    end
  end

  describe 'callback methods' do
    describe '#on_new_message' do
      let(:message) { Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'Hello') }

      it 'calls callback with new_message event' do
        callback_result = nil
        callback = proc { |event| callback_result = event }

        agent.on_new_message(message, &callback)

        expect(callback_result).to eq({
                                        type: :new_message,
                                        message: message
                                      })
      end
    end

    describe '#on_tool_call' do
      let(:tool) { create_tool(name: 'test_tool') }
      let(:tool_arguments) { { param: 'value' } }

      it 'calls callback with tool_call event' do
        callback_result = nil
        callback = proc { |event| callback_result = event }

        agent.on_tool_call(tool: tool, tool_arguments: tool_arguments, &callback)

        expect(callback_result).to eq({
                                        type: :tool_call,
                                        tool: tool,
                                        tool_arguments: tool_arguments
                                      })
      end
    end

    describe '#on_tool_response' do
      let(:tool_response) { 'result' }
      let(:message) { Ruboty::AiAgent::ChatMessage.new(role: :tool, content: tool_response) }

      it 'calls callback with tool_response event' do
        callback_result = nil
        callback = proc { |event| callback_result = event }

        agent.on_tool_response(tool_response: tool_response, message: message, &callback)

        expect(callback_result).to eq({
                                        type: :tool_response,
                                        tool_response: tool_response,
                                        message: message
                                      })
      end
    end

    describe '#on_response' do
      let(:response) { instance_double(Ruboty::AiAgent::LLM::Response) }

      it 'calls callback with response event' do
        callback_result = nil
        callback = proc { |event| callback_result = event }

        agent.on_response(response, &callback)

        expect(callback_result).to eq({
                                        type: :response,
                                        response: response
                                      })
      end
    end
  end
end
