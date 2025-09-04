# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records for a specific user.
    class UserAssociations < RecordSet
      attr_reader :user_id #: String

      def initialize(database:, user_id:)
        super(database:)

        @user_id = user_id
      end

      class << self
        attr_accessor :association_key
      end

      def association_key #: Symbol
        self.class.association_key || raise(NotImplementedError, 'Subclasses must set the association_key method')
      end

      def namespace_keys
        [:users, user_id, assoication_type]
      end
    end
  end
end
