# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Memorize and retrieve information using Ruboty's brain.
    class Database
      # @rbs!
      #   type keynable = Symbol | String | Integer

      autoload :QueryMethods, 'ruboty/ai_agent/database/query_methods'

      include QueryMethods

      NAMESPACE = :ai_agent

      attr_reader :brain #: Ruboty::Brains::Base

      # @rbs brain: Ruboty::Brains::Base
      def initialize(brain)
        @brain = brain
      end

      def data #: Hash[keynable, untyped]
        brain.data[NAMESPACE] ||= {} # steep:ignore UnannotatedEmptyCollection
      end

      def user(id) #: User
        User.find_or_create(database: self, id: id)
      end

      def chat_thread(id) #: ChatThread
        ChatThread.find_or_create(database: self, id: id)
      end
    end
  end
end
