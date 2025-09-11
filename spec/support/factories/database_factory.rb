# frozen_string_literal: true

module DatabaseFactory
  include RobotFactory

  def create_database(data = {})
    brain = create_brain(data)
    Ruboty::AiAgent::Database.new(brain)
  end
end
