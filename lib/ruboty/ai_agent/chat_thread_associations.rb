# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records for a specific thread.
    class ChatThreadAssociations < RecordSet
      attr_reader :chat_thread_id #: String

      def initialize(database:, chat_thread_id:)
        super(database:)

        @chat_thread_id = chat_thread_id
      end

      class << self
        attr_accessor :association_key
      end

      def association_key #: Symbol
        self.class.association_key || raise(NotImplementedError, 'Subclasses must set the association_key method')
      end

      def namespace_keys
        [:chat_threads, chat_thread_id, assoication_type]
      end
    end
  end
end
