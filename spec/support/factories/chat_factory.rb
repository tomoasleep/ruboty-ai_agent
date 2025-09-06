# frozen_string_literal: true

module ChatFactory
  include DatabaseFactory

  def create_chat_thread_with_database(id: 'thread123', database_data: {})
    database = create_database(database_data)
    database.chat_thread(id)
  end

  def create_chat_thread_with_messages(id: 'thread123', messages: [])
    database = create_database
    chat_thread = database.chat_thread(id)

    messages.each do |message|
      chat_message = if message.is_a?(Ruboty::AiAgent::ChatMessage)
                       message
                     else
                       create_sample_chat_message(**message)
                     end
      chat_thread.messages << chat_message
    end

    chat_thread
  end

  def create_conversation_history(thread_id: 'conversation123')
    messages = [
      create_sample_chat_message(role: :system, content: 'You are a helpful assistant'),
      create_sample_chat_message(role: :user, content: 'Hello, how are you?'),
      create_sample_chat_message(role: :assistant,
                                 content: 'Hello! I\'m doing well, thank you for asking. How can I help you today?'),
      create_sample_chat_message(role: :user, content: 'What is the weather like?'),
      create_sample_chat_message(role: :assistant, content: 'I don\'t have access to real-time weather information.')
    ]

    create_chat_thread_with_messages(id: thread_id, messages: messages)
  end

  def create_tool_conversation(thread_id: 'tool_conversation123')
    messages = [
      create_sample_chat_message(role: :user, content: 'Calculate 2 + 2'),
      create_sample_chat_message(
        role: :assistant,
        content: nil,
        tool_call_id: 'call_123',
        tool_name: 'calculator',
        tool_arguments: { expression: '2 + 2' }
      ),
      create_sample_chat_message(
        role: :tool,
        content: '4',
        tool_call_id: 'call_123'
      ),
      create_sample_chat_message(role: :assistant, content: 'The result is 4.')
    ]

    create_chat_thread_with_messages(id: thread_id, messages: messages)
  end
end
