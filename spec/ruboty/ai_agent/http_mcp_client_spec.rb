# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Ruboty::AiAgent::HttpMcpClient do
  include McpMockHelper
  let(:base_url) { 'http://localhost:9292' }
  let(:headers) { { 'Authorization' => 'Bearer token123' } }
  let(:client) { described_class.new(url: base_url, headers: headers) }
  let(:session_id) { 'test-session-123' }

  describe '#initialize' do
    it 'sets base_url and headers' do
      expect(client.base_url).to eq(base_url)
      expect(client.headers).to eq(headers)
      expect(client.session_id).to be_nil
    end
  end

  describe '#initialize_session' do
    before do
      stub_mcp_initialize(
        base_url: base_url,
        session_id: session_id,
        headers: headers
      )
    end

    it 'initializes session and returns session_id' do
      result = client.initialize_session
      expect(result).to eq(session_id)
      expect(client.session_id).to eq(session_id)
    end
  end

  describe '#ping' do
    subject(:ping_result) { client.ping }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_ping(
        base_url: base_url,
        headers: headers,
        pong_result: true
      )
    end

    it { is_expected.to eq([{ 'jsonrpc' => '2.0', 'id' => 'test-id', 'result' => { 'pong' => true } }]) }
  end

  describe '#list_tools' do
    subject(:list_tools_result) { client.list_tools }

    let(:tools) { [{ 'name' => 'echo', 'description' => 'Echoes back messages' }] }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_list_tools(
        base_url: base_url,
        headers: headers,
        tools: tools
      )
    end

    it { is_expected.to eq(tools) }
  end

  describe '#call_tool' do
    subject(:call_tool_result) { client.call_tool(tool_name, tool_arguments) }

    let(:tool_name) { 'echo' }
    let(:tool_arguments) { { message: 'Hello MCP!' } }
    let(:response_content) { 'Echo: Hello MCP!' }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_call_tool(
        base_url: base_url,
        headers: headers,
        tool_name: tool_name,
        tool_arguments: tool_arguments,
        response_content: response_content
      )
    end

    it { is_expected.to eq([response_content]) }

    context 'with streaming (SSE)' do
      let(:streaming_chunks) { [{ 'content' => 'First chunk' }, { 'content' => 'Second chunk' }] }

      before do
        # Mock ensure_initialized to avoid automatic initialization
        allow(client).to receive(:ensure_initialized)

        stub_mcp_call_tool_streaming(
          base_url: base_url,
          headers: headers,
          tool_name: tool_name,
          tool_arguments: tool_arguments,
          streaming_chunks: streaming_chunks
        )
      end

      it 'handles streaming response with a block' do
        results = []
        client.call_tool(tool_name, tool_arguments) do |chunk|
          results << chunk
        end

        expect(results).to eq([
                                { 'jsonrpc' => '2.0', 'id' => '1', 'result' => { 'content' => 'First chunk' } },
                                { 'jsonrpc' => '2.0', 'id' => '2', 'result' => { 'content' => 'Second chunk' } }
                              ])
      end
    end
  end

  describe '#list_prompts' do
    subject(:list_prompts_result) { client.list_prompts }

    let(:prompts) { [{ 'name' => 'example_prompt', 'description' => 'An example prompt' }] }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_list_prompts(
        base_url: base_url,
        headers: headers,
        prompts: prompts
      )
    end

    it {
      expect(list_prompts_result).to eq([{ 'jsonrpc' => '2.0', 'id' => 'test-id',
                                           'result' => { 'prompts' => prompts } }])
    }
  end

  describe '#get_prompt' do
    subject(:get_prompt_result) { client.get_prompt(prompt_name, prompt_arguments) }

    let(:prompt_name) { 'example_prompt' }
    let(:prompt_arguments) { { input: 'test' } }
    let(:response_prompt) { 'Generated prompt text' }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_get_prompt(
        base_url: base_url,
        headers: headers,
        prompt_name: prompt_name,
        prompt_arguments: prompt_arguments,
        response_prompt: response_prompt
      )
    end

    it {
      expect(get_prompt_result).to eq([{ 'jsonrpc' => '2.0', 'id' => 'test-id',
                                         'result' => { 'prompt' => response_prompt } }])
    }
  end

  describe '#list_resources' do
    subject(:list_resources_result) { client.list_resources }

    let(:resources) { [{ 'uri' => 'test://resource', 'name' => 'Test Resource' }] }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_list_resources(
        base_url: base_url,
        headers: headers,
        resources: resources
      )
    end

    it {
      expect(list_resources_result).to eq([{ 'jsonrpc' => '2.0', 'id' => 'test-id',
                                             'result' => { 'resources' => resources } }])
    }
  end

  describe '#read_resource' do
    subject(:read_resource_result) { client.read_resource(resource_uri) }

    let(:resource_uri) { 'test://resource' }
    let(:response_content) { 'Resource content' }

    before do
      # Mock ensure_initialized to avoid automatic initialization
      allow(client).to receive(:ensure_initialized)

      stub_mcp_read_resource(
        base_url: base_url,
        headers: headers,
        resource_uri: resource_uri,
        response_content: response_content
      )
    end

    it {
      expect(read_resource_result).to eq([{ 'jsonrpc' => '2.0', 'id' => 'test-id', 'result' => { 'content' => response_content } }])
    }
  end

  describe '#cleanup_session' do
    before do
      client.instance_variable_set(:@session_id, session_id)
      stub_mcp_cleanup_session(
        base_url: base_url,
        headers: headers,
        session_id: session_id
      )
    end

    it 'sends DELETE request and clears session_id' do
      client.cleanup_session
      expect(client.session_id).to be_nil
    end

    context 'when session_id is nil' do
      before do
        client.instance_variable_set(:@session_id, nil)
      end

      it 'does nothing' do
        allow(Net::HTTP).to receive(:new)
        client.cleanup_session
        expect(Net::HTTP).not_to have_received(:new)
      end
    end
  end

  describe 'error handling' do
    describe 'HTTP errors' do
      before do
        stub_mcp_error(
          base_url: base_url,
          headers: headers,
          http_status: 500,
          error_body: 'Internal Server Error'
        )
      end

      it 'raises Error for non-200 responses' do
        expect { client.ping }.to raise_error(
          Ruboty::AiAgent::HttpMcpClient::Error,
          /HTTP 500/
        )
      end
    end

    describe 'JSON-RPC errors' do
      before do
        stub_mcp_json_rpc_error(
          base_url: base_url,
          headers: headers,
          error_code: -32_601,
          error_message: 'Method not found'
        )
      end

      it 'raises Error for JSON-RPC errors' do
        expect { client.ping }.to raise_error(
          Ruboty::AiAgent::HttpMcpClient::Error,
          /JSON-RPC Error -32601: Method not found/
        )
      end
    end
  end
end
