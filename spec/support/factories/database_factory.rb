# frozen_string_literal: true

module DatabaseFactory
  def create_database(data = {})
    brain = create_brain(data)
    Ruboty::AiAgent::Database.new(brain)
  end

  def create_brain(data = {})
    brain_data = { Ruboty::AiAgent::Database::NAMESPACE => data }

    Ruboty::Brains::Memory.new.tap do |brain|
      brain.data.merge!(brain_data)
    end
  end

  def create_database_with_users(user_configs = {})
    users_data = user_configs.transform_values do |config|
      {
        mcp_configurations: config.fetch(:mcp_configurations, {}),
        ai_memories: config.fetch(:ai_memories, {})
      }
    end

    create_database(users: users_data)
  end

  def create_database_with_chat_threads(thread_configs = {})
    threads_data = thread_configs.transform_values do |config|
      {
        messages: config.fetch(:messages, [])
      }
    end

    create_database(chat_threads: threads_data)
  end

  def create_database_with_messages(thread_id, messages)
    thread_data = {
      thread_id => {
        messages: messages.map(&:to_h)
      }
    }

    create_database(chat_thread_messages: thread_data)
  end

  def create_chat_message(role:, content:, **options)
    Ruboty::AiAgent::ChatMessage.new(
      role: role,
      content: content,
      **options
    )
  end

  def create_mcp_configuration(name:, **options)
    defaults = {
      transport: 'http',
      headers: {},
      url: 'http://localhost:3000'
    }

    Ruboty::AiAgent::McpConfiguration.new(
      name: name,
      **defaults.merge(options)
    )
  end

  def create_tool(name:, **options)
    defaults = {
      title: "#{name.capitalize} Tool",
      description: "A tool for #{name}",
      input_schema: {
        'type' => 'object',
        'properties' => {},
        'required' => []
      }
    }

    Ruboty::AiAgent::Tool.new(
      name: name,
      **defaults.merge(options)
    ) do |params|
      "#{name} called with #{params}"
    end
  end
end
