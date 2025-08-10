# frozen_string_literal: true

module AiMemory
  class Configuration
    attr_accessor :storage_path, :openai_api_key, :embedding_model, :embedding_dimensions,
                  :max_user_memories, :max_session_memories, :similarity_threshold,
                  :extraction_temperature, :extraction_max_tokens, :logger
    
    # Vector database configurations
    attr_accessor :redis_enabled, :redis_url, :redis_index_name,
                  :pgvector_enabled, :pgvector_table_name,
                  :pinecone_enabled, :pinecone_api_key, :pinecone_environment, :pinecone_index_name
    
    def initialize
      # Default storage configuration
      @storage_path = "storage/memories"
      @max_user_memories = 100
      @max_session_memories = 30
      @similarity_threshold = 0.7
      
      # Default AI configuration
      @openai_api_key = ENV['OAI_ACCESS_TOKEN'] || ENV['OPENAI_API_KEY']
      @embedding_model = "text-embedding-ada-002"
      @embedding_dimensions = 1536
      @extraction_temperature = 0.1
      @extraction_max_tokens = 800
      
      # Vector database configuration from environment
      @redis_enabled = ENV['REDIS_VECTOR_ENABLED'] == 'true'
      @redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
      @redis_index_name = ENV['REDIS_INDEX_NAME'] || 'memory_vectors'
      
      @pgvector_enabled = ENV['PGVECTOR_ENABLED'] == 'true'
      @pgvector_table_name = ENV['PGVECTOR_TABLE'] || 'memory_embeddings'
      
      @pinecone_enabled = ENV['PINECONE_ENABLED'] == 'true'
      @pinecone_api_key = ENV['PINECONE_API_KEY']
      @pinecone_environment = ENV['PINECONE_ENVIRONMENT']
      @pinecone_index_name = ENV['PINECONE_INDEX_NAME'] || 'memory-index'
      
      # Default logger
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end
    
    def vector_db_enabled?
      redis_enabled || pgvector_enabled || pinecone_enabled
    end
    
    def validate!
      raise ConfigurationError, "OpenAI API key is required" if openai_api_key.nil? || openai_api_key.empty?
      raise ConfigurationError, "Storage path cannot be empty" if storage_path.nil? || storage_path.empty?
      
      if pinecone_enabled
        raise ConfigurationError, "Pinecone API key is required when Pinecone is enabled" if pinecone_api_key.nil?
        raise ConfigurationError, "Pinecone environment is required when Pinecone is enabled" if pinecone_environment.nil?
      end
      
      true
    end
  end
end
