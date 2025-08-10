# frozen_string_literal: true

module AiMemory
  module VectorAdapters
    class PineconeAdapter < BaseAdapter
      def initialize(config)
        super(config)
        @client = initialize_pinecone_client
      end
      
      def available?
        @client && @config.pinecone_enabled
      end
      
      def store_memory(memory, user_id, session_id)
        return unless available?
        
        embedding = generate_embedding(memory["content"])
        return unless embedding
        
        vector_id = "#{user_id}_#{Digest::MD5.hexdigest(memory['content'])}"
        
        @client.upsert(
          index_name: @config.pinecone_index_name,
          vectors: [{
            id: vector_id,
            values: embedding,
            metadata: {
              content: memory['content'],
              category: memory['category'],
              importance: memory['importance'],
              type: memory['type'],
              timestamp: memory['timestamp'],
              user_id: user_id,
              session_id: session_id
            }
          }]
        )
        
        log_info("Stored memory in Pinecone: #{memory['content'][0..50]}...")
      rescue => e
        log_error("Failed to store memory in Pinecone: #{e.message}")
      end
      
      def search_similar(query, limit, user_id:)
        return [] unless available?
        
        query_embedding = generate_embedding(query)
        return [] unless query_embedding
        
        response = @client.query(
          index_name: @config.pinecone_index_name,
          vector: query_embedding,
          top_k: limit,
          filter: { user_id: user_id },
          include_metadata: true
        )
        
        response['matches'].map do |match|
          {
            content: match['metadata']['content'],
            category: match['metadata']['category'],
            importance: match['metadata']['importance'],
            timestamp: match['metadata']['timestamp'],
            type: match['metadata']['type'],
            similarity: match['score']
          }
        end
      rescue => e
        log_error("Pinecone search failed: #{e.message}")
        []
      end
      
      def clear_user_vectors(user_id)
        return unless available?
        
        # Pinecone doesn't support bulk delete by metadata filter in free tier
        # This would require fetching all vectors and deleting individually
        log_info("Clear user vectors not implemented for Pinecone (requires paid tier)")
      rescue => e
        log_error("Failed to clear user vectors: #{e.message}")
      end
      
      def clear_session_vectors(session_id)
        return unless available?
        
        # Similar limitation as clear_user_vectors
        log_info("Clear session vectors not implemented for Pinecone (requires paid tier)")
      rescue => e
        log_error("Failed to clear session vectors: #{e.message}")
      end
      
      private
      
      def initialize_pinecone_client
        require 'pinecone'
        Pinecone::Client.new(
          api_key: @config.pinecone_api_key,
          environment: @config.pinecone_environment
        )
      rescue LoadError
        log_error("Pinecone gem not available. Install with: gem install pinecone")
        nil
      rescue => e
        log_error("Failed to initialize Pinecone client: #{e.message}")
        nil
      end
    end
  end
end
