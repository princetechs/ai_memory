# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AiMemory::VectorAdapters::RedisAdapter do
  let(:config) do
    AiMemory::Configuration.new.tap do |c|
      c.openai_api_key = 'test-key'
      c.redis_enabled = true
      c.redis_url = 'redis://localhost:6379'
      c.logger = Logger.new('/dev/null')
    end
  end
  
  let(:adapter) { described_class.new(config) }
  
  describe '#available?' do
    context 'when redis is enabled and client is initialized' do
      before do
        allow(adapter).to receive(:initialize_redis_client).and_return(double('redis_client'))
      end
      
      it 'returns true' do
        expect(adapter.available?).to be true
      end
    end
    
    context 'when redis client fails to initialize' do
      it 'returns false' do
        mock_client = double('redis_client')
        allow(Redis).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:ping).and_raise(Redis::CannotConnectError)
        
        adapter = described_class.new(config)
        expect(adapter.available?).to be false
      end
    end
  end
  
  describe '#store_memory' do
    let(:memory) do
      {
        'content' => 'User likes pizza',
        'category' => 'preferences',
        'importance' => 'high',
        'type' => 'user',
        'timestamp' => Time.now.iso8601
      }
    end
    
    let(:mock_client) { double('redis_client') }
    
    before do
      allow(adapter).to receive(:initialize_redis_client).and_return(mock_client)
      allow(adapter).to receive(:generate_embedding).and_return([0.1, 0.2, 0.3])
    end
    
    it 'stores memory with embedding in Redis' do
      allow(adapter).to receive(:available?).and_return(false)
      
      result = adapter.store_memory(memory, 'test_user')
      expect(result).to be_nil
    end
  end
  
  describe '#search_similar' do
    it 'searches for similar memories' do
      mock_client = double('redis_client')
      allow(adapter).to receive(:client).and_return(mock_client)
      allow(adapter).to receive(:generate_embedding).and_return([0.1, 0.2, 0.3])
      
      # Mock Redis search operations
      allow(mock_client).to receive(:ft_search).and_return({
        'results' => [
          {
            'id' => 'memory:test_user:hash1',
            'values' => {
              'content' => 'Test memory',
              'category' => 'test',
              'timestamp' => Time.now.iso8601
            }
          }
        ]
      })
      
      results = adapter.search_similar('test query', 5, user_id: 'test_user')
      expect(results).to be_an(Array)
    end
  end
end
