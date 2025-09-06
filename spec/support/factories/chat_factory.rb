# frozen_string_literal: true

module ChatFactory
  include DatabaseFactory

  def create_chat_thread(database:, id: 'thread123', messages: [])
    chat_thread = database.chat_thread(id)

    messages.each do |message|
      chat_message = if message.is_a?(Ruboty::AiAgent::ChatMessage)
                       message
                     else
                       create_chat_message(**message)
                     end
      chat_thread.messages << chat_message
    end

    chat_thread
  end

  def create_conversation_history(database:, thread_id: 'conversation123')
    messages = [
      create_chat_message(role: :system, content: 'You are a helpful assistant'),
      create_chat_message(role: :user, content: 'Hello, how are you?'),
      create_chat_message(role: :assistant,
                          content: 'Hello! I\'m doing well, thank you for asking. How can I help you today?'),
      create_chat_message(role: :user, content: 'What is the weather like?'),
      create_chat_message(role: :assistant, content: 'I don\'t have access to real-time weather information.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end

  def create_tool_conversation(database:, thread_id: 'tool_conversation123')
    messages = [
      create_chat_message(role: :user, content: 'Calculate 2 + 2'),
      create_chat_message(
        role: :assistant,
        content: nil,
        tool_call_id: 'call_123',
        tool_name: 'calculator',
        tool_arguments: { expression: '2 + 2' }
      ),
      create_chat_message(
        role: :tool,
        content: '4',
        tool_call_id: 'call_123'
      ),
      create_chat_message(role: :assistant, content: 'The result is 4.')
    ]

    create_chat_thread(database: database, id: thread_id, messages: messages)
  end
end
