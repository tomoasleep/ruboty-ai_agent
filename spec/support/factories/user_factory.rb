# frozen_string_literal: true

module UserFactory
  include DatabaseFactory

  def create_user(database:, id: 'test_user', mcp_configs: {}, memories: [])
    user = database.user(id)

    unless mcp_configs.empty?
      mcp_configs.each do |name, config|
        if config.is_a?(Ruboty::AiAgent::McpConfiguration)
          user.mcp_configurations.add(config)
        else
          create_mcp_configuration(user_id: id, name:, **config)
        end
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

  def create_mcp_configuration(database:, user_id:, name:, **options)
    user = database.user(user_id)

    defaults = {
      transport: 'http',
      headers: {},
      url: 'http://localhost:3000'
    }

    mcp_config = Ruboty::AiAgent::McpConfiguration.new(
      name: name,
      **defaults.merge(options)
    )

    user.mcp_configurations.add(mcp_config)
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
