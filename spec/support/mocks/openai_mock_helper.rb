# frozen_string_literal: true

module OpenAIMockHelper
  def stub_openai_chat_completion(messages:, tools: [], response_content: nil, response_tool_calls: nil)
    request_body = {
      model: 'gpt-5',
      messages: format_messages_for_request(messages),
      tools: format_tools_for_request(tools)
    }

    response_body = build_chat_completion_response(
      content: response_content,
      tool_calls: response_tool_calls
    )

    stub_request(:post, 'https://api.openai.com/v1/chat/completions')
      .with(body: hash_including(request_body))
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_openai_chat_completion_with_tool_call(messages:, tools:, tool_name:, tool_arguments:,
                                                 tool_call_id: 'call_123')
    stub_openai_chat_completion(
      messages: messages,
      tools: tools,
      response_tool_calls: [
        {
          id: tool_call_id,
          type: 'function',
          function: {
            name: tool_name,
            arguments: tool_arguments.to_json
          }
        }
      ]
    )
  end

  def stub_openai_chat_completion_with_content(messages:, response_content:, tools: [])
    stub_openai_chat_completion(
      messages: messages,
      tools: tools,
      response_content: response_content
    )
  end

  private

  def format_messages_for_request(messages)
    messages.map do |msg|
      case msg
      when Ruboty::AiAgent::ChatMessage
        format_chat_message_for_request(msg)
      when Hash
        msg
      else
        raise ArgumentError, "Unknown message type: #{msg.class}"
      end
    end
  end

  def format_chat_message_for_request(message)
    case message.role.to_sym
    when :system
      { role: 'system', content: message.content }
    when :user
      { role: 'user', content: message.content }
    when :assistant
      if message.tool_call_id
        {
          role: 'assistant',
          content: message.content,
          tool_calls: [
            {
              id: message.tool_call_id,
              type: 'function',
              function: {
                name: message.tool_name,
                arguments: message.tool_arguments.to_json
              }
            }
          ]
        }
      else
        { role: 'assistant', content: message.content, tool_calls: nil }
      end
    when :tool
      { role: 'tool', tool_call_id: message.tool_call_id, content: message.content }
    else
      raise ArgumentError, "Unknown message role: #{message.role}"
    end
  end

  def format_tools_for_request(tools)
    tools.map do |tool|
      case tool
      when Ruboty::AiAgent::Tool
        {
          type: 'function',
          function: {
            name: tool.name,
            description: tool.description,
            parameters: tool.input_schema || {
              type: 'object',
              properties: {},
              required: []
            }
          }
        }
      when Hash
        tool
      else
        raise ArgumentError, "Unknown tool type: #{tool.class}"
      end
    end
  end

  def build_chat_completion_response(content: nil, tool_calls: nil)
    message = {
      role: 'assistant'
    }

    if tool_calls
      message[:content] = nil
      message[:tool_calls] = tool_calls
      finish_reason = 'tool_calls'
    else
      message[:content] = content || 'Default response'
      finish_reason = 'stop'
    end

    {
      id: 'chatcmpl-123',
      object: 'chat.completion',
      created: 1_677_652_288,
      model: 'gpt-5',
      choices: [
        {
          index: 0,
          message: message,
          finish_reason: finish_reason
        }
      ],
      usage: {
        prompt_tokens: 50,
        completion_tokens: 20,
        total_tokens: 70
      }
    }
  end

  def expect_openai_request_made(messages: nil, tools: nil)
    expectation = a_request(:post, 'https://api.openai.com/v1/chat/completions')

    if messages || tools
      body_hash = {}
      body_hash[:messages] = format_messages_for_request(messages) if messages
      body_hash[:tools] = format_tools_for_request(tools) if tools
      expectation = expectation.with(body: hash_including(body_hash))
    end

    expect(expectation).to have_been_made.once
  end
end

RSpec.configure do |config|
  config.include OpenAIMockHelper
end
