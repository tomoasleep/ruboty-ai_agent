# frozen_string_literal: true

module Ruboty
  module AiAgent
    # LLM-related backends and its utilities.
    module LLM
      autoload :OpenAI, 'ruboty/ai_agent/llm/openai'
      autoload :Response, 'ruboty/ai_agent/llm/response'
    end
  end
end
