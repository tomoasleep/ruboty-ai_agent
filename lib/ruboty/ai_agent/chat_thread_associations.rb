# frozen_string_literal: true

module Ruboty
  module AiAgent
    # A set of records for a specific thread.
    # @rbs generic Record
    class ChatThreadAssociations < RecordSet #[Record]
      attr_reader :chat_thread_id #: String

      def initialize(database:, chat_thread_id:)
        super(database:)

        @chat_thread_id = chat_thread_id
      end

      # @rbs!
      #   def self.association_key: () -> Symbol
      #   def self.association_key=: (Symbol) -> Symbol

      # @rbs skip
      class << self
        attr_accessor :association_key
      end

      def association_key #: Symbol
        self.class.association_key || raise(NotImplementedError, 'Subclasses must set the association_key method')
      end

      def namespace_keys
        [:chat_threads, chat_thread_id, association_key]
      end
    end
  end
end
