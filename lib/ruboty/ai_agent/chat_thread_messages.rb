# frozen_string_literal: true

module Ruboty
  module AiAgent
    # Manage messages for the chat thread.
    class ChatThreadMessages < ChatThreadAssociations #[ChatMessage]
      self.association_key = :messages

      # @rbs message: ChatMessage
      def add(message) #: void
        store(message, key: (keys.last.to_s.to_i || -1) + 1)
      end

      alias << add

      # Check if any message's token usage exceeds auto compact threshold
      # @rbs return: bool
      def over_auto_compact_threshold?
        all_values.any? { |message| message.token_usage&.over_auto_compact_threshold? }
      end

      # Compact chat messages by summarizing them
      # @rbs llm: LLM::OpenAI
      # @rbs return: void
      def compact(llm:)
        messages = all_values
        return if messages.empty?

        last_assistant_message = messages.reverse.find { |msg| msg.role == :assistant }

        summary = summarize(llm:)

        clear
        add(ChatMessage.new(
              role: :system,
              content: "Previous conversation summary: #{summary}"
            ))
        add(last_assistant_message) if last_assistant_message&.tool_call?
      end

      # Generate summary of chat messages
      # @rbs llm: LLM::OpenAI
      # @rbs return: String
      def summarize(llm:)
        summary_prompt = ChatMessage.new(
          role: :system,
          content: <<~TEXT
            Please summarize the following conversation in a concise manner, capturing the key topics, decisions, and context that would be helpful for continuing the conversation:
          TEXT
        )

        response = llm.complete(messages: [summary_prompt, *all_values])
        response.message.content
      end
    end
  end
end
