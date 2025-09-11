# frozen_string_literal: true

module RobotFactory
  include EnvMockHelper

  def create_brain(data = {}) #: Ruboty::Brains::Memory
    brain_data = { Ruboty::AiAgent::Database::NAMESPACE => data }

    Ruboty::Brains::Memory.new.tap do |brain|
      brain.data.merge!(brain_data)
    end
  end

  def create_robot(brain = create_brain, env: {}) #: Ruboty::Robot
    stub_env(**env) if env.any?

    Ruboty::Robot.new.tap do |robot|
      robot.singleton_class.class_eval do
        define_method(:brain) { brain }
        def bundle; end

        def adapter
          @adapter ||= TestAdapter.new(self)
        end
      end
    end
  end

  class TestAdapter < Ruboty::Adapters::Base
    attr_reader :messages

    def initialize(*)
      super
      @messages = []
    end

    def run; end

    def say(message)
      @messages << message
    end
  end
end
