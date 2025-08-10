# frozen_string_literal: true

module AiMemory
  module VectorAdapters
    class RedisAdapter < BaseAdapter
      def initialize(config)
        super(config)
        @client = initialize_redis_client
      end
      
      def available?
        return false unless @config.redis_enabled
        return false unless @client
        
        begin
          @client.ping
          true
        rescue => e
          @logger&.error("Redis not available: #{e.message}")
          false
        end
      end
      
      def store_memory(memory, user_id)
        return unless available?
        
        embedding = generate_embedding(memory["content"])
        return unless embedding
        
        vector_key = "memory:#{user_id}:#{Digest::MD5.hexdigest(memory['content'])}"
        
        @client.hset(vector_key, {
          'content' => memory['content'],
          'category' => memory['category'],
          'importance' => memory['importance'],
          'type' => memory['type'],
          'timestamp' => memory['timestamp'],
          'user_id' => user_id,
          'embedding' => embedding.to_json
        })
        
        # Add to user index
        @client.sadd("memory_index:#{user_id}", vector_key)
        
        log_info("Stored memory in Redis: #{memory['content'][0..50]}...")
      rescue => e
        log_error("Failed to store memory in Redis: #{e.message}")
      end
      
      def search_similar(query, limit, user_id:)
        return [] unless available?
        
        query_embedding = generate_embedding(query)
        return [] unless query_embedding
        
        memory_keys = @client.smembers("memory_index:#{user_id}")
        similarities = []
        
        memory_keys.each do |key|
          memory_data = @client.hgetall(key)
          next unless memory_data['embedding']
          
          stored_embedding = JSON.parse(memory_data['embedding'])
          similarity = cosine_similarity(query_embedding, stored_embedding)
          
          similarities << {
            similarity: similarity,
            content: memory_data['content'],
            category: memory_data['category'],
            importance: memory_data['importance'],
            timestamp: memory_data['timestamp'],
            type: memory_data['type']
          }
        end
        
        similarities.sort_by { |s| -s[:similarity] }.first(limit)
      rescue => e
        log_error("Redis vector search failed: #{e.message}")
        []
      end
      
      def clear_user_vectors(user_id)
        return unless available?
        
        memory_keys = @client.smembers("memory_index:#{user_id}")
        return if memory_keys.empty?
        
        @client.del(*memory_keys)
        @client.del("memory_index:#{user_id}")
        
        log_info("Cleared #{memory_keys.count} vectors for user: #{user_id}")
      rescue => e
        log_error("Failed to clear user vectors: #{e.message}")
      end
      
      def clear_session_vectors(session_id)
        return unless available?
        
        # Find all memories for this session
        all_keys = @client.keys("memory:*")
        session_keys = []
        
        all_keys.each do |key|
          memory_data = @client.hgetall(key)
          session_keys << key if memory_data['session_id'] == session_id
        end
        
        return if session_keys.empty?
        
        @client.del(*session_keys)
        log_info("Cleared #{session_keys.count} session vectors for session: #{session_id}")
      rescue => e
        log_error("Failed to clear session vectors: #{e.message}")
      end
      
      private
      
      def initialize_redis_client
        require 'redis'
        Redis.new(url: @config.redis_url)
      rescue LoadError
        log_error("Redis gem not available. Install with: gem install redis")
        nil
      rescue => e
        log_error("Failed to initialize Redis client: #{e.message}")
        nil
      end
    end
  end
end
