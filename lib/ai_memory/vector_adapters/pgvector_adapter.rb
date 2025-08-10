# frozen_string_literal: true

module AiMemory
  module VectorAdapters
    class PgvectorAdapter < BaseAdapter
      def initialize(config)
        super(config)
        @connection = initialize_connection
        create_table if available?
      end
      
      def available?
        @connection && @config.pgvector_enabled
      end
      
      def store_memory(memory, user_id, session_id)
        return unless available?
        
        embedding = generate_embedding(memory["content"])
        return unless embedding
        
        @connection.exec_params(
          "INSERT INTO #{table_name} 
           (content, category, importance, type, timestamp, user_id, session_id, embedding) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (content, user_id) DO UPDATE SET 
           timestamp = EXCLUDED.timestamp, embedding = EXCLUDED.embedding",
          [
            memory['content'],
            memory['category'],
            memory['importance'],
            memory['type'],
            memory['timestamp'],
            user_id,
            session_id,
            "[#{embedding.join(',')}]"
          ]
        )
        
        log_info("Stored memory in PGVector: #{memory['content'][0..50]}...")
      rescue => e
        log_error("Failed to store memory in PGVector: #{e.message}")
      end
      
      def search_similar(query, limit, user_id:)
        return [] unless available?
        
        query_embedding = generate_embedding(query)
        return [] unless query_embedding
        
        result = @connection.exec_params(
          "SELECT content, category, importance, timestamp, type,
                  embedding <=> $1 AS distance
           FROM #{table_name} 
           WHERE user_id = $2 
           ORDER BY embedding <=> $1 
           LIMIT $3",
          ["[#{query_embedding.join(',')}]", user_id, limit]
        )
        
        result.map do |row|
          {
            content: row['content'],
            category: row['category'],
            importance: row['importance'],
            timestamp: row['timestamp'],
            type: row['type'],
            similarity: 1.0 - row['distance'].to_f
          }
        end
      rescue => e
        log_error("PGVector search failed: #{e.message}")
        []
      end
      
      def clear_user_vectors(user_id)
        return unless available?
        
        result = @connection.exec_params(
          "DELETE FROM #{table_name} WHERE user_id = $1",
          [user_id]
        )
        
        log_info("Cleared #{result.cmd_tuples} vectors for user: #{user_id}")
      rescue => e
        log_error("Failed to clear user vectors: #{e.message}")
      end
      
      def clear_session_vectors(session_id)
        return unless available?
        
        result = @connection.exec_params(
          "DELETE FROM #{table_name} WHERE session_id = $1",
          [session_id]
        )
        
        log_info("Cleared #{result.cmd_tuples} session vectors for session: #{session_id}")
      rescue => e
        log_error("Failed to clear session vectors: #{e.message}")
      end
      
      private
      
      def initialize_connection
        if defined?(ActiveRecord)
          ActiveRecord::Base.connection.raw_connection
        else
          require 'pg'
          PG.connect(ENV['DATABASE_URL'])
        end
      rescue LoadError
        log_error("PG gem not available. Install with: gem install pg")
        nil
      rescue => e
        log_error("Failed to initialize PGVector connection: #{e.message}")
        nil
      end
      
      def table_name
        @config.pgvector_table_name
      end
      
      def create_table
        # Enable vector extension
        @connection.exec("CREATE EXTENSION IF NOT EXISTS vector;")
        
        # Create table
        @connection.exec(
          "CREATE TABLE IF NOT EXISTS #{table_name} (
            id SERIAL PRIMARY KEY,
            content TEXT NOT NULL,
            category VARCHAR(100),
            importance VARCHAR(20),
            type VARCHAR(20),
            timestamp TIMESTAMP,
            user_id VARCHAR(100),
            session_id VARCHAR(100),
            embedding vector(#{@config.embedding_dimensions}),
            UNIQUE(content, user_id)
          );"
        )
        
        # Create indexes
        @connection.exec(
          "CREATE INDEX IF NOT EXISTS idx_#{table_name}_user 
           ON #{table_name} (user_id);"
        )
        
        @connection.exec(
          "CREATE INDEX IF NOT EXISTS idx_#{table_name}_vector 
           ON #{table_name} 
           USING ivfflat (embedding vector_cosine_ops);"
        )
        
        log_info("PGVector table and indexes created successfully")
      rescue => e
        log_error("Failed to create PGVector table: #{e.message}")
      end
    end
  end
end
