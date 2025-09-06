# frozen_string_literal: true

module McpMockHelper
  def stub_mcp_initialize(base_url:, session_id: 'test-session-123', headers: {})
    request_body = {
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

    response_body = {
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

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { 'Mcp-Session-Id' => session_id }
      )
  end

  def stub_mcp_ping(base_url:, headers: {}, pong_result: true)
    request_body = {
      jsonrpc: '2.0',
      method: 'ping',
      id: anything
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { pong: pong_result }
    }

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_list_tools(base_url:, headers: {}, tools: [])
    request_body = {
      jsonrpc: '2.0',
      method: 'tools/list',
      id: anything
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { tools: tools }
    }

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_call_tool(base_url:, tool_name:, headers: {}, tool_arguments: {}, response_content: nil)
    request_body = {
      jsonrpc: '2.0',
      method: 'tools/call',
      id: anything,
      params: {
        name: tool_name,
        arguments: tool_arguments
      }
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { content: response_content }
    }

    stub_request(:post, base_url)
      .with(body: hash_including(request_body), headers: build_headers(headers))
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_call_tool_streaming(base_url:, tool_name:, headers: {}, tool_arguments: {}, streaming_chunks: [])
    request_body = {
      jsonrpc: '2.0',
      method: 'tools/call',
      id: anything,
      params: {
        name: tool_name,
        arguments: tool_arguments
      }
    }

    sse_response = streaming_chunks.map.with_index do |chunk, index|
      "data: #{JSON.generate({ jsonrpc: '2.0', id: (index + 1).to_s, result: chunk })}\n\n"
    end.join

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: sse_response,
        headers: { 'Content-Type' => 'text/event-stream' }
      )
  end

  def stub_mcp_list_prompts(base_url:, headers: {}, prompts: [])
    request_body = {
      jsonrpc: '2.0',
      method: 'prompts/list',
      id: anything
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { prompts: prompts }
    }

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_get_prompt(base_url:, prompt_name:, headers: {}, prompt_arguments: {}, response_prompt: nil)
    request_body = {
      jsonrpc: '2.0',
      method: 'prompts/get',
      id: anything,
      params: {
        name: prompt_name,
        arguments: prompt_arguments
      }
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { prompt: response_prompt }
    }

    stub_request(:post, base_url)
      .with(body: hash_including(request_body), headers: build_headers(headers))
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_list_resources(base_url:, headers: {}, resources: [])
    request_body = {
      jsonrpc: '2.0',
      method: 'resources/list',
      id: anything
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { resources: resources }
    }

    stub_request(:post, base_url)
      .with(
        body: hash_including(request_body),
        headers: build_headers(headers)
      )
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_read_resource(base_url:, resource_uri:, headers: {}, response_content: nil)
    request_body = {
      jsonrpc: '2.0',
      method: 'resources/read',
      id: anything,
      params: {
        uri: resource_uri
      }
    }

    response_body = {
      jsonrpc: '2.0',
      id: 'test-id',
      result: { content: response_content }
    }

    stub_request(:post, base_url)
      .with(body: hash_including(request_body), headers: build_headers(headers))
      .to_return(
        status: 200,
        body: response_body.to_json
      )
  end

  def stub_mcp_cleanup_session(base_url:, session_id:, headers: {})
    stub_request(:delete, base_url)
      .with(
        headers: build_headers(headers).merge('Mcp-Session-Id' => session_id)
      )
      .to_return(status: 200)
  end

  def stub_mcp_error(base_url:, headers: {}, http_status: 500, error_body: 'Internal Server Error')
    stub_request(:post, base_url)
      .with(headers: build_headers(headers))
      .to_return(
        status: http_status,
        body: error_body
      )
  end

  def stub_mcp_json_rpc_error(base_url:, headers: {}, error_code: -32_601, error_message: 'Method not found')
    error_response = {
      jsonrpc: '2.0',
      id: 'test-id',
      error: {
        code: error_code,
        message: error_message
      }
    }

    stub_request(:post, base_url)
      .with(headers: build_headers(headers))
      .to_return(
        status: 200,
        body: error_response.to_json
      )
  end

  private

  def build_headers(custom_headers = {})
    base_headers = {
      'Accept' => 'application/json, text/event-stream',
      'Content-Type' => 'application/json'
    }
    base_headers.merge(custom_headers)
  end
end
