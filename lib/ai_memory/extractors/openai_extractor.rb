# frozen_string_literal: true

require 'openai'

module AiMemory
  module Extractors
    class OpenaiExtractor < BaseExtractor
      EXTRACTION_PROMPT = <<~PROMPT
        You are an intelligent memory extraction system. Analyze the conversation and extract only the most important, factual information that should be remembered.

        Extract memories in these categories ONLY if they contain significant information:
        1. Personal facts (name, age, location, occupation, family)
        2. Preferences and interests (likes, dislikes, hobbies)
        3. Goals and objectives (short-term and long-term)
        4. Important events or milestones
        5. Skills and expertise
        6. Current projects or activities

        Rules:
        - Extract only factual, specific information
        - Avoid generic or obvious statements
        - Focus on information that would be useful for future conversations
        - Each memory should be concise and actionable

        Return ONLY a JSON object with this structure:
        {
          "memories": [
            {
              "content": "specific factual information",
              "category": "personal_facts|preferences|goals|events|skills|projects",
              "importance": "high|medium|low",
              "type": "user|session"
            }
          ]
        }

        If no significant information is found, return: {"memories": []}
      PROMPT
      
      def initialize(config)
        super(config)
        @client = OpenAI::Client.new(access_token: @config.openai_api_key)
      end
      
      def extract_memories(conversation_text)
        response = @client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              { role: "system", content: EXTRACTION_PROMPT },
              { role: "user", content: "Analyze this conversation:\n\n#{conversation_text}" }
            ],
            max_tokens: @config.extraction_max_tokens,
            temperature: @config.extraction_temperature,
            response_format: { type: "json_object" }
          }
        )
        
        content = response.dig("choices", 0, "message", "content")
        return [] unless content
        
        parsed_response = JSON.parse(content)
        memories = parsed_response["memories"] || []
        
        log_info("Extracted #{memories.count} memories from conversation")
        memories
        
      rescue JSON::ParserError => e
        log_error("Failed to parse extraction response: #{e.message}")
        []
      rescue => e
        log_error("Memory extraction failed: #{e.message}")
        []
      end
      
      def generate_embedding(text)
        return nil unless text&.length&.> 10
        
        response = @client.embeddings(
          parameters: {
            model: @config.embedding_model,
            input: text
          }
        )
        
        response.dig("data", 0, "embedding")
      rescue => e
        log_error("Failed to generate embedding: #{e.message}")
        nil
      end
    end
  end
end
