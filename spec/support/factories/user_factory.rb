# frozen_string_literal: true

module UserFactory
  include DatabaseFactory

  def create_user(database:, id: 'test_user', mcp_configs: {}, memories: [])
    user = database.user(id)

    unless mcp_configs.empty?
      mcp_configs.each do |name, config|
        mcp_config = if config.is_a?(Ruboty::AiAgent::McpConfiguration)
                       config
                     else
                       create_mcp_configuration(name: name, **config)
                     end
        user.mcp_configurations.add(mcp_config)
      end
    end

    unless memories.empty?
      memories.each do |memory_text|
        # AI memories の追加ロジックは実装に応じて調整
        user.ai_memories.add(memory_text)
      end
    end

    user
  end
end
