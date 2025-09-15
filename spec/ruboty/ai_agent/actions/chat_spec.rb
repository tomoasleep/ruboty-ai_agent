# frozen_string_literal: true

require 'spec_helper'
require 'openai'

RSpec.describe Ruboty::AiAgent::Actions::Chat do
  include OpenAIMockHelper
  include McpMockHelper
  include RobotFactory

  subject(:receive_message) { robot.receive(body: "#{robot.name} #{body}", from:, to:) }

  let(:action) { described_class.new(message) }

  let(:robot) { create_robot(env:) }
  let(:brain) { robot.brain }
  let(:database) { Ruboty::AiAgent::Database.new(brain) }
  let(:env) do
    {
      'OPENAI_API_KEY' => 'test_api_key',
      'OPENAI_MODEL' => 'gpt-5-nano',
      'DEBUG' => nil,
      'OPENAI_ORG_ID' => nil
    }
  end

  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'Hello, AI!' }

  def said_messages #: Array[Hash[untyped, untyped]]
    robot.adapter.messages
  end

  context 'when chat completes successfully' do
    let(:chat_thread) { database.chat_thread(from) }
    let(:messages) { chat_thread.messages.all_values }

    before do
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body }
        ],
        response_content: 'Hello! How can I help you today?'
      )
    end

    it 'adds user message to chat thread' do
      receive_message
      expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
    end

    it 'adds assistant response to chat thread' do
      receive_message
      expect(messages.any? { |m| m.role == :assistant && m.content == 'Hello! How can I help you today?' }).to be true
    end

    it 'replies with assistant message' do
      receive_message
      expect(said_messages).to include(a_hash_including(body: 'Hello! How can I help you today?'))
    end

    describe 'conversation history preservation' do
      subject(:receive_message_second) do
        # Setup second API call stub
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: body },
            { role: 'assistant', content: 'Hello! How can I help you today?' },
            { role: 'user', content: second_body }
          ],
          response_content: 'I cannot check the weather in real-time.'
        )

        robot.receive(from:, to:, body: "#{robot.name} #{second_body}")
      end

      let(:second_body) { 'What is the weather?' }

      it 'preserves all messages in order' do
        receive_message
        receive_message_second

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

    before do
      # Configure user with MCP that provides the tool
      user = database.user(from)
      user.mcp_configurations.add(
        Ruboty::AiAgent::McpConfiguration.new(
          name: 'calc_server',
          transport: :http,
          headers: {},
          url: 'http://localhost:3000'
        )
      )

      # Mock MCP HTTP calls
      stub_mcp_initialize(
        base_url: 'http://localhost:3000'
      )

      stub_mcp_list_tools(
        base_url: 'http://localhost:3000',
        tools: [
          {
            'name' => 'calculator',
            'description' => 'Performs calculations',
            'inputSchema' => {}
          }
        ]
      )

      stub_mcp_call_tool(
        base_url: 'http://localhost:3000',
        tool_name: 'calculator',
        tool_arguments: { expression: '21 * 2' },
        response_content: '42'
      )

      # First API call - returns tool call
      stub_openai_chat_completion_with_tool_call(
        messages: [
          { role: 'user', content: body }
        ],
        tools: including(
          a_hash_including(
            'type' => 'function',
            'function' => {
              'name' => 'mcp_calc_server__calculator',
              'description' => 'Performs calculations',
              'parameters' => {}
            }
          )
        ),
        tool_name: 'mcp_calc_server__calculator',
        tool_arguments: { expression: '21 * 2' },
        tool_call_id: 'call_123'
      )

      # Second API call - after tool execution
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body },
          {
            role: 'assistant',
            content: '',
            tool_calls: [
              {
                id: 'call_123',
                type: 'function',
                function: {
                  name: 'mcp_calc_server__calculator',
                  arguments: '{"expression":"21 * 2"}'
                }
              }
            ]
          },
          { role: 'tool', tool_call_id: 'call_123', content: '["42"]' }
        ],
        tools: including(
          a_hash_including(
            'type' => 'function',
            'function' => {
              'name' => 'mcp_calc_server__calculator',
              'description' => 'Performs calculations',
              'parameters' => {}
            }
          )
        ),
        response_content: 'The answer is 42.'
      )
    end

    it 'notifies about tool call' do
      receive_message

      expect(said_messages).to match([
                                       a_hash_including(body: 'Calling tool mcp_calc_server__calculator with arguments {"expression":"21 * 2"}'),
                                       a_hash_including(body: 'Tool response: ["42"]'),
                                       a_hash_including(body: 'The answer is 42.')
                                     ])
    end

    it 'adds tool messages to chat thread' do
      receive_message

      aggregate_failures do
        expect(messages.any? { |m| m.role == :user }).to be true
        expect(messages.any? { |m| m.role == :assistant && m.tool_name == 'mcp_calc_server__calculator' }).to be true
        expect(messages.any? { |m| m.role == :tool }).to be true
        expect(messages.any? { |m| m.role == :assistant && m.content == 'The answer is 42.' }).to be true
      end
    end
  end

  context 'when user is not specified' do
    let(:from) { nil }
    let(:chat_thread) { database.chat_thread('default') }
    let(:messages) { chat_thread.messages.all_values }

    before do
      stub_openai_chat_completion_with_content(
        messages: [
          { role: 'user', content: body }
        ],
        response_content: 'Hello! How can I help you today?'
      )
    end

    it 'uses default as user identifier' do
      receive_message
      expect(messages.any? { |m| m.role == :user && m.content == body }).to be true
    end
  end

  context 'when an error occurs' do
    before do
      # Stub the API to return an error
      stub_request(:post, 'https://api.openai.com/v1/chat/completions')
        .to_return(status: 500, body: 'Internal Server Error')
    end

    it 'replies with error message' do
      receive_message

      expect(said_messages).to include(a_hash_including(body: /エラーが発生しました/))
    end
  end

  describe 'system prompt usage in chat' do
    def set_system_prompt(scope:, prompt:)
      robot.receive(body: "#{robot.name} set #{scope} system prompt \"#{prompt}\"", from:, to:)
    end

    def send_chat_message(message)
      robot.receive(body: "#{robot.name} #{message}", from:, to:)
    end

    context 'with user system prompt set' do
      let(:user_prompt) { 'You are a helpful assistant' }
      let(:chat_message) { 'Hello!' }

      before do
        set_system_prompt(scope: 'user', prompt: user_prompt)
      end

      it 'sends user system prompt to OpenAI API' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: user_prompt },
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hi there! How can I help you?'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hi there! How can I help you?')
      end
    end

    context 'with global system prompt set' do
      let(:global_prompt) { 'Be concise in your responses' }
      let(:chat_message) { 'What is AI?' }

      before do
        set_system_prompt(scope: 'global', prompt: global_prompt)
      end

      it 'sends global system prompt to OpenAI API' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: global_prompt },
            { role: 'user', content: chat_message }
          ],
          response_content: 'AI is artificial intelligence.'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('AI is artificial intelligence.')
      end
    end

    context 'with both global and user system prompts set' do
      let(:global_prompt) { 'Be concise' }
      let(:user_prompt) { 'You are a helpful assistant' }
      let(:chat_message) { 'Hello!' }

      before do
        set_system_prompt(scope: 'global', prompt: global_prompt)
        set_system_prompt(scope: 'user', prompt: user_prompt)
      end

      it 'sends both system prompts in correct order (global first, then user)' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: global_prompt },
            { role: 'system', content: user_prompt },
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hi! How can I assist you today?'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hi! How can I assist you today?')
      end
    end

    context 'without system prompt set' do
      let(:chat_message) { 'Hello!' }

      it 'sends only user message without system prompts' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hello! How can I help you?'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hello! How can I help you?')
      end
    end

    context 'with existing chat history and system prompt' do
      let(:user_prompt) { 'You are a helpful assistant' }
      let(:first_message) { 'What is 2+2?' }
      let(:second_message) { 'Thank you!' }

      before do
        set_system_prompt(scope: 'user', prompt: user_prompt)

        # First message
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: user_prompt },
            { role: 'user', content: first_message }
          ],
          response_content: '2+2 equals 4.'
        )
        send_chat_message(first_message)
      end

      it 'includes system prompt with all chat history' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: user_prompt },
            { role: 'user', content: first_message },
            { role: 'assistant', content: '2+2 equals 4.' },
            { role: 'user', content: second_message }
          ],
          response_content: 'You\'re welcome!'
        )

        send_chat_message(second_message)

        expect(said_messages.last[:body]).to include('You\'re welcome!')
      end
    end
  end

  describe 'AI Memory usage in chat' do
    def add_memory(memory_text)
      robot.receive(body: "#{robot.name} add ai memory \"#{memory_text}\"", from:, to:)
    end

    def send_chat_message(message)
      robot.receive(body: "#{robot.name} #{message}", from:, to:)
    end

    context 'with AI memories added' do
      let(:coffee_memory) { 'I like coffee' }
      let(:color_memory) { 'My favorite color is blue' }
      let(:chat_message) { 'Hello!' }

      before do
        add_memory(coffee_memory)
        add_memory(color_memory)
      end

      it 'includes AI memories as user message before conversation' do
        expected_memory_content = "My memories:\n#{coffee_memory}\n\n#{color_memory}"

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: expected_memory_content },
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hello! I know you like coffee and your favorite color is blue.'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hello! I know you like coffee and your favorite color is blue.')
      end
    end

    context 'with system prompt and AI memories' do
      let(:user_prompt) { 'You are a helpful assistant' }
      let(:memory) { 'I am a developer' }
      let(:chat_message) { 'Hello!' }

      before do
        robot.receive(body: "#{robot.name} set user system prompt \"#{user_prompt}\"", from:, to:)
        add_memory(memory)
      end

      it 'includes system prompt, then AI memories, then conversation' do
        expected_memory_content = "My memories:\n#{memory}"

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'system', content: user_prompt },
            { role: 'user', content: expected_memory_content },
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hello! I understand you are a developer.'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hello! I understand you are a developer.')
      end
    end

    context 'without AI memories' do
      let(:chat_message) { 'Hello!' }

      it 'does not include memory messages when no memories exist' do
        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: chat_message }
          ],
          response_content: 'Hello! How can I help you?'
        )

        send_chat_message(chat_message)

        expect(said_messages.last[:body]).to include('Hello! How can I help you?')
      end
    end

    context 'with conversation history and AI memories' do
      let(:memory) { 'I work at a tech company' }
      let(:first_message) { 'What is your advice for developers?' }
      let(:second_message) { 'Thank you!' }

      before do
        add_memory(memory)

        expected_memory_content = "My memories:\n#{memory}"

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: expected_memory_content },
            { role: 'user', content: first_message }
          ],
          response_content: 'Since you work at a tech company, I recommend continuous learning.'
        )

        send_chat_message(first_message)
      end

      it 'includes memories only once at the beginning of conversation' do
        expected_memory_content = "My memories:\n#{memory}"

        stub_openai_chat_completion_with_content(
          messages: [
            { role: 'user', content: expected_memory_content },
            { role: 'user', content: first_message },
            { role: 'assistant', content: 'Since you work at a tech company, I recommend continuous learning.' },
            { role: 'user', content: second_message }
          ],
          response_content: 'You\'re welcome!'
        )

        send_chat_message(second_message)

        expect(said_messages.last[:body]).to include('You\'re welcome!')
      end
    end
  end
end
