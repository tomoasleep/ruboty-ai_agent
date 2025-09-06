# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  subject(:action) { described_class.new(message) }

  let(:robot) { Ruboty::Robot.new }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'Hello, AI!' }

  let(:original_message) do
    Ruboty::Message.new(
      body: body,
      from: from,
      to: to,
      robot: robot
    )
  end

  let(:message) do
    # Actions::Chat expects a message with reply method and [] accessor
    message = original_message
    allow(message).to receive(:reply)
    allow(message).to receive(:[]).with(:body).and_return(body)
    message
  end

  # Mock only the LLM
  let(:llm) { instance_double('Ruboty::AiAgent::LLM::OpenAI') }
  let(:llm_response) do
    Ruboty::AiAgent::LLM::Response.new(
      message: Ruboty::AiAgent::ChatMessage.new(
        role: :assistant,
        content: 'Hello! How can I help you today?'
      ),
      tool: nil,
      tool_call_id: nil,
      tool_arguments: nil
    )
  end

  before do
    # Stub ENV variables
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_api_key')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-5-nano').and_return('gpt-4')
    allow(ENV).to receive(:[]).with('DEBUG').and_return(nil)

    # Mock OpenAI client to avoid ENV access
    openai_client = instance_double('OpenAI::Client')
    allow(OpenAI::Client).to receive(:new).and_return(openai_client)

    # Mock only the LLM creation
    allow(Ruboty::AiAgent::LLM::OpenAI).to receive(:new).and_return(llm)
    allow(llm).to receive(:complete).and_return(llm_response)

    # Allow action to use real database
    allow(action).to receive(:database).and_return(database)
    allow(action).to receive(:robot).and_return(robot)
  end

  describe '#call' do
    subject(:call_action) { action.call }

    context 'when chat completes successfully' do
      let(:chat_thread) { database.chat_thread(from) }
      let(:messages) { chat_thread.messages.all_values }

      it 'adds user message to chat thread' do
        call_action
        expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
      end

      it 'adds assistant response to chat thread' do
        call_action
        expect(messages.any? { |m| m.role == :assistant && m.content == 'Hello! How can I help you today?' }).to be true
      end

      it 'replies with assistant message' do
        expect(message).to receive(:reply).with('Hello! How can I help you today?')
        call_action
      end

      describe 'conversation history preservation' do
        subject(:second_call) do
          action.call
          allow(message).to receive(:[]).with(:body).and_return(second_body)
          allow(llm).to receive(:complete).and_return(second_response)
          action.call
        end

        let(:second_body) { 'What is the weather?' }
        let(:second_response) do
          Ruboty::AiAgent::LLM::Response.new(
            message: Ruboty::AiAgent::ChatMessage.new(
              role: :assistant,
              content: 'I cannot check the weather in real-time.'
            ),
            tool: nil,
            tool_call_id: nil,
            tool_arguments: nil
          )
        end

        it 'preserves all messages in order' do
          second_call

          expect(messages.length).to eq(4)
          expect(messages[0]).to have_attributes(role: :user, content: body)
          expect(messages[1]).to have_attributes(role: :assistant)
          expect(messages[2]).to have_attributes(role: :user, content: second_body)
          expect(messages[3]).to have_attributes(role: :assistant)
        end
      end
    end

    context 'when tool is called' do
      let(:chat_thread) { database.chat_thread(from) }
      let(:messages) { chat_thread.messages.all_values }

      let(:tool) do
        Ruboty::AiAgent::Tool.new(
          name: 'calculator',
          title: 'Calculator',
          description: 'Performs calculations',
          input_schema: {}
        ) { |_args| '42' }
      end

      let(:tool_call_response) do
        Ruboty::AiAgent::LLM::Response.new(
          message: Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: nil,
            tool_call_id: 'call_123',
            tool_name: 'calculator',
            tool_arguments: { expression: '21 * 2' }
          ),
          tool: tool,
          tool_call_id: 'call_123',
          tool_arguments: { expression: '21 * 2' }
        )
      end

      let(:tool_result_response) do
        Ruboty::AiAgent::LLM::Response.new(
          message: Ruboty::AiAgent::ChatMessage.new(
            role: :assistant,
            content: 'The answer is 42.'
          ),
          tool: nil,
          tool_call_id: nil,
          tool_arguments: nil
        )
      end

      before do
        # Configure user with MCP that provides the tool
        user = database.user(from)
        user.mcp_configurations.add(
          Ruboty::AiAgent::McpConfiguration.new(
            name: 'calc_server',
            transport: 'http',
            headers: {},
            url: 'http://localhost:3000'
          )
        )

        # Mock MCP client to return our tool
        mcp_client = instance_double('Ruboty::AiAgent::HttpMcpClient')
        allow(Ruboty::AiAgent::HttpMcpClient).to receive(:new).and_return(mcp_client)
        allow(mcp_client).to receive(:list_tools).and_return([
                                                               {
                                                                 'name' => 'calculator',
                                                                 'description' => 'Performs calculations',
                                                                 'inputSchema' => {}
                                                               }
                                                             ])
        allow(mcp_client).to receive(:call_tool).with('calculator', expression: '21 * 2').and_return('42')

        # LLM first returns tool call, then returns final response
        allow(llm).to receive(:complete).and_return(tool_call_response, tool_result_response)
      end

      it 'notifies about tool call' do
        expect(message).to receive(:reply).with(
          'Calling tool calculator with arguments {expression: "21 * 2"}',
          streaming: true
        )
        expect(message).to receive(:reply).with('Tool response: 42')
        expect(message).to receive(:reply).with('The answer is 42.')

        call_action
      end

      it 'adds tool messages to chat thread' do
        call_action

        aggregate_failures do
          expect(messages.any? { |m| m.role == :user }).to be true
          expect(messages.any? { |m| m.role == :assistant && m.tool_name == 'calculator' }).to be true
          expect(messages.any? { |m| m.role == :tool }).to be true
          expect(messages.any? { |m| m.role == :assistant && m.content == 'The answer is 42.' }).to be true
        end
      end
    end

    context 'when user is not specified' do
      let(:from) { nil }
      let(:chat_thread) { database.chat_thread('default') }
      let(:messages) { chat_thread.messages.all_values }

      it 'uses default as user identifier' do
        call_action
        expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
      end
    end

    context 'when an error occurs' do
      before do
        allow(llm).to receive(:complete).and_raise(StandardError, 'API Error')
      end

      it 'replies with error message' do
        expect(message).to receive(:reply).with('エラーが発生しました: API Error')
        call_action
      end

      context 'with DEBUG environment variable' do
        let(:error) { StandardError.new('API Error') }

        before do
          allow(ENV).to receive(:[]).with('DEBUG').and_return('true')
          allow(error).to receive(:full_message).and_return("API Error\n  from spec_file.rb:123")
          allow(llm).to receive(:complete).and_raise(error)
        end

        it 'replies with full error message' do
          expect(message).to receive(:reply).with("エラーが発生しました: API Error\n  from spec_file.rb:123")
          call_action
        end
      end
    end
  end

  describe '#body_param' do
    subject { action.body_param }

    it { is_expected.to eq(body) }
  end
end
