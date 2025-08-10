# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AiMemory::Configuration do
  let(:config) { described_class.new }
  
  describe '#initialize' do
    it 'sets default values' do
      expect(config.storage_path).to eq('storage/memories')
      expect(config.max_user_memories).to eq(100)
      expect(config.max_session_memories).to eq(30)
      expect(config.similarity_threshold).to eq(0.7)
      expect(config.embedding_model).to eq('text-embedding-ada-002')
      expect(config.embedding_dimensions).to eq(1536)
    end
    
    it 'reads from environment variables' do
      ENV['REDIS_VECTOR_ENABLED'] = 'true'
      ENV['REDIS_URL'] = 'redis://test:6379'
      
      new_config = described_class.new
      expect(new_config.redis_enabled).to be true
      expect(new_config.redis_url).to eq('redis://test:6379')
      
      ENV.delete('REDIS_VECTOR_ENABLED')
      ENV.delete('REDIS_URL')
    end
  end
  
  describe '#vector_db_enabled?' do
    it 'returns false when no vector databases are enabled' do
      expect(config.vector_db_enabled?).to be false
    end
    
    it 'returns true when redis is enabled' do
      config.redis_enabled = true
      expect(config.vector_db_enabled?).to be true
    end
    
    it 'returns true when pgvector is enabled' do
      config.pgvector_enabled = true
      expect(config.vector_db_enabled?).to be true
    end
    
    it 'returns true when pinecone is enabled' do
      config.pinecone_enabled = true
      expect(config.vector_db_enabled?).to be true
    end
  end
  
  describe '#validate!' do
    it 'raises error when openai_api_key is missing' do
      config.openai_api_key = nil
      expect { config.validate! }.to raise_error(AiMemory::ConfigurationError, /OpenAI API key is required/)
    end
    
    it 'raises error when storage_path is empty' do
      config.openai_api_key = 'test-key'
      config.storage_path = ''
      expect { config.validate! }.to raise_error(AiMemory::ConfigurationError, /Storage path cannot be empty/)
    end
    
    it 'raises error when pinecone is enabled but api_key is missing' do
      config.openai_api_key = 'test-key'
      config.pinecone_enabled = true
      config.pinecone_api_key = nil
      expect { config.validate! }.to raise_error(AiMemory::ConfigurationError, /Pinecone API key is required/)
    end
    
    it 'validates successfully with proper configuration' do
      config.openai_api_key = 'test-key'
      expect(config.validate!).to be true
    end
  end
end
