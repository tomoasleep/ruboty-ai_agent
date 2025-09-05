# frozen_string_literal: true

require 'spec_helper'
require 'ruboty/ai_agent/http_mcp_client'
require 'webmock/rspec'

RSpec.describe Ruboty::AiAgent::HttpMcpClient do
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
    let(:request_body) do
      {
        jsonrpc: '2.0',
        method: 'initialize',
        id: anything,
        params: {
          protocolVersion: '2024-11-05',
          capabilities: {},
          clientInfo: {
            name: 'ruboty-ai_agent',
            version: '1.0'
          }
        }
      }
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          protocolVersion: '2024-11-05',
          capabilities: {},
          serverInfo: {
            name: 'test-server',
            version: '1.0'
          }
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .with(
          body: hash_including(request_body),
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token123'
          }
        )
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { 'Mcp-Session-Id' => session_id }
        )
    end

    it 'initializes session and returns session_id' do
      result = client.initialize_session
      expect(result).to eq(session_id)
      expect(client.session_id).to eq(session_id)
    end
  end

  describe '#ping' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:request_body) do
      {
        jsonrpc: '2.0',
        method: 'ping',
        id: anything
      }
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: { pong: true }
      }
    end

    before do
      stub_request(:post, base_url)
        .with(
          body: hash_including(request_body),
          headers: {
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token123'
          }
        )
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'sends ping request' do
      result = client.ping
      expect(result).to eq({ 'pong' => true })
    end
  end

  describe '#list_tools' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          tools: [
            { name: 'echo', description: 'Echoes back messages' }
          ]
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'lists available tools' do
      result = client.list_tools
      expect(result).to eq({
        'tools' => [
          { 'name' => 'echo', 'description' => 'Echoes back messages' }
        ]
      })
    end
  end

  describe '#call_tool' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:request_body) do
      {
        jsonrpc: '2.0',
        method: 'tools/call',
        id: anything,
        params: {
          name: 'echo',
          arguments: { message: 'Hello MCP!' }
        }
      }
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: 'Echo: Hello MCP!'
      }
    end

    before do
      stub_request(:post, base_url)
        .with(body: hash_including(request_body))
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'calls a tool with arguments' do
      result = client.call_tool('echo', { message: 'Hello MCP!' })
      expect(result).to eq('Echo: Hello MCP!')
    end

    context 'with streaming (SSE)' do
      let(:sse_response) do
        [
          "data: {\"jsonrpc\":\"2.0\",\"id\":\"1\",\"result\":\"First chunk\"}\n\n",
          "data: {\"jsonrpc\":\"2.0\",\"id\":\"2\",\"result\":\"Second chunk\"}\n\n"
        ].join
      end

      before do
        stub_request(:post, base_url)
          .with(
            body: hash_including(request_body),
            headers: {
              'Accept' => 'text/event-stream',
              'Content-Type' => 'application/json',
              'Authorization' => 'Bearer token123'
            }
          )
          .to_return(
            status: 200,
            body: sse_response,
            headers: { 'Content-Type' => 'text/event-stream' }
          )
      end

      it 'handles streaming response with a block' do
        results = []
        client.call_tool('echo', { message: 'Hello MCP!' }) do |chunk|
          results << chunk
        end
        
        expect(results).to eq([
          { 'jsonrpc' => '2.0', 'id' => '1', 'result' => 'First chunk' },
          { 'jsonrpc' => '2.0', 'id' => '2', 'result' => 'Second chunk' }
        ])
      end
    end
  end

  describe '#list_prompts' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          prompts: [
            { name: 'example_prompt', description: 'An example prompt' }
          ]
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'lists available prompts' do
      result = client.list_prompts
      expect(result).to eq({
        'prompts' => [
          { 'name' => 'example_prompt', 'description' => 'An example prompt' }
        ]
      })
    end
  end

  describe '#get_prompt' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:request_body) do
      {
        jsonrpc: '2.0',
        method: 'prompts/get',
        id: anything,
        params: {
          name: 'example_prompt',
          arguments: { input: 'test' }
        }
      }
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          prompt: 'Generated prompt text'
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .with(body: hash_including(request_body))
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'gets a prompt with arguments' do
      result = client.get_prompt('example_prompt', { input: 'test' })
      expect(result).to eq({ 'prompt' => 'Generated prompt text' })
    end
  end

  describe '#list_resources' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          resources: [
            { uri: 'test://resource', name: 'Test Resource' }
          ]
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'lists available resources' do
      result = client.list_resources
      expect(result).to eq({
        'resources' => [
          { 'uri' => 'test://resource', 'name' => 'Test Resource' }
        ]
      })
    end
  end

  describe '#read_resource' do
    before do
      allow(client).to receive(:session_id).and_return(session_id)
    end

    let(:request_body) do
      {
        jsonrpc: '2.0',
        method: 'resources/read',
        id: anything,
        params: {
          uri: 'test://resource'
        }
      }
    end

    let(:response_body) do
      {
        jsonrpc: '2.0',
        id: 'test-id',
        result: {
          content: 'Resource content'
        }
      }
    end

    before do
      stub_request(:post, base_url)
        .with(body: hash_including(request_body))
        .to_return(
          status: 200,
          body: response_body.to_json
        )
    end

    it 'reads a resource by URI' do
      result = client.read_resource('test://resource')
      expect(result).to eq({ 'content' => 'Resource content' })
    end
  end

  describe '#cleanup_session' do
    before do
      client.instance_variable_set(:@session_id, session_id)
    end

    before do
      stub_request(:delete, base_url)
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => 'Bearer token123',
            'Mcp-Session-Id' => session_id
          }
        )
        .to_return(status: 200)
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
        expect(Net::HTTP).not_to receive(:new)
        client.cleanup_session
      end
    end
  end

  describe 'error handling' do
    describe 'HTTP errors' do
      before do
        stub_request(:post, base_url)
          .to_return(
            status: 500,
            body: 'Internal Server Error'
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
      let(:error_response) do
        {
          jsonrpc: '2.0',
          id: 'test-id',
          error: {
            code: -32601,
            message: 'Method not found'
          }
        }
      end

      before do
        stub_request(:post, base_url)
          .to_return(
            status: 200,
            body: error_response.to_json
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