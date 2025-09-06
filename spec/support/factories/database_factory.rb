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
end
