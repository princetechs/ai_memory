# frozen_string_literal: true

module AiMemory
  module VectorAdapters
    class BaseAdapter
      attr_reader :config
      
      def initialize(config)
        @config = config
      end
      
      def available?
        false
      end
      
      def store_memory(memory, user_id, session_id)
        raise NotImplementedError, "Subclasses must implement store_memory method"
      end
      
      def search_similar(query, limit, user_id:)
        raise NotImplementedError, "Subclasses must implement search_similar method"
      end
      
      def clear_user_vectors(user_id)
        raise NotImplementedError, "Subclasses must implement clear_user_vectors method"
      end
      
      def clear_session_vectors(session_id)
        raise NotImplementedError, "Subclasses must implement clear_session_vectors method"
      end
      
      protected
      
      def generate_embedding(text)
        return nil unless text&.length&.> 10
        
        begin
          require 'openai'
          client = OpenAI::Client.new(access_token: @config.openai_api_key)
          
          response = client.embeddings(
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
      
      def cosine_similarity(vec1, vec2)
        return 0.0 if vec1.empty? || vec2.empty?
        
        dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
        magnitude1 = Math.sqrt(vec1.map { |a| a * a }.sum)
        magnitude2 = Math.sqrt(vec2.map { |a| a * a }.sum)
        
        return 0.0 if magnitude1 == 0.0 || magnitude2 == 0.0
        
        dot_product / (magnitude1 * magnitude2)
      end
      
      def log_info(message)
        @config.logger&.info("[AiMemory::VectorAdapter] #{message}")
      end
      
      def log_error(message)
        @config.logger&.error("[AiMemory::VectorAdapter] #{message}")
      end
    end
  end
end
