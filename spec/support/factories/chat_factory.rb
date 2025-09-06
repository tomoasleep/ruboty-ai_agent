# frozen_string_literal: true

module ChatFactory
  include DatabaseFactory

  def create_chat_thread(database:, id: 'thread123', messages: [])
    chat_thread = database.chat_thread(id)

    messages.each do |message|
      chat_message = if message.is_a?(Ruboty::AiAgent::ChatMessage)
                       message
                     else
                       Ruboty::AiAgent::ChatMessage.new(**message)
                     end
      chat_thread.messages << chat_message
    end

    chat_thread
  end

  def create_conversation_history(database:, thread_id: 'conversation123')
    messages = [
      Ruboty::AiAgent::ChatMessage.new(role: :system, content: 'You are a helpful assistant'),
      Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Hello, how are you?'),
      Ruboty::AiAgent::ChatMessage.new(role: :assistant,
                                       content: 'Hello! I\'m doing well, thank you for asking. How can I help you today?'),
      Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'What is the weather like?'),
      Ruboty::AiAgent::ChatMessage.new(role: :assistant,
                                       content: 'I don\'t have access to real-time weather information.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end

  def create_tool_conversation(database:, thread_id: 'tool_conversation123')
    messages = [
      Ruboty::AiAgent::ChatMessage.new(role: :user, content: 'Calculate 2 + 2'),
      Ruboty::AiAgent::ChatMessage.new(
        role: :assistant,
        content: nil,
        tool_call_id: 'call_123',
        tool_name: 'calculator',
        tool_arguments: { expression: '2 + 2' }
      ),
      Ruboty::AiAgent::ChatMessage.new(
        role: :tool,
        content: '4',
        tool_call_id: 'call_123'
      ),
      Ruboty::AiAgent::ChatMessage.new(role: :assistant, content: 'The result is 4.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end
end
