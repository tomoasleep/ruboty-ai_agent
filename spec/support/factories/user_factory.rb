# frozen_string_literal: true

module UserFactory
  include DatabaseFactory

  def create_user_with_database(id: 'test_user', database_data: {})
    database = create_database(database_data)
    database.user(id)
  end

  def create_user_with_mcp_configurations(id: 'test_user', mcp_configs: {})
    database = create_database
    user = database.user(id)

    mcp_configs.each do |name, config|
      mcp_config = if config.is_a?(Ruboty::AiAgent::McpConfiguration)
                     config
                   else
                     create_sample_mcp_configuration(name: name, **config)
                   end
      user.mcp_configurations.add(mcp_config)
    end

    user
  end

  def create_user_with_ai_memories(id: 'test_user', memories: [])
    database = create_database
    user = database.user(id)

    memories.each do |memory_text|
      # AI memories の追加ロジックは実装に応じて調整
      user.ai_memories.add(memory_text)
    end

    user
  end
end
