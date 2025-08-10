# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AiMemory::MemoryService do
  let(:config) do
    AiMemory::Configuration.new.tap do |c|
      c.openai_api_key = 'test-key'
      c.storage_path = 'tmp/test_memories'
      c.logger = Logger.new('/dev/null')
    end
  end
  
  let(:memory_service) do
    described_class.new(
      user_id: 'test_user',
      session_id: 'test_session',
      config: config
    )
  end
  
  before do
    FileUtils.rm_rf('tmp/test_memories')
    FileUtils.mkdir_p('tmp/test_memories')
  end
  
  after do
    FileUtils.rm_rf('tmp/test_memories')
  end
  
  describe '#initialize' do
    it 'creates storage directory' do
      expect(Dir.exist?('tmp/test_memories')).to be true
    end
    
    it 'sets user_id and session_id' do
      expect(memory_service.user_id).to eq('test_user')
      expect(memory_service.session_id).to eq('test_session')
    end
  end
  
  describe '#get_memory_stats' do
    it 'returns memory statistics' do
      stats = memory_service.get_memory_stats
      
      expect(stats).to include(
        :user_memories,
        :session_memories,
        :total_memories,
        :vector_db_enabled,
        :vector_db_type
      )
    end
  end
  
  describe '#format_memories_for_prompt' do
    let(:memories) do
      [
        { 'content' => 'User likes pizza', 'category' => 'preferences', 'timestamp' => Time.now.iso8601 },
        { 'content' => 'User is a developer', 'category' => 'personal_facts' }
      ]
    end
    
    it 'formats memories for AI prompt injection' do
      result = memory_service.format_memories_for_prompt(memories)
      
      expect(result).to include('=== MEMORY CONTEXT ===')
      expect(result).to include('Preferences: User likes pizza')
      expect(result).to include('Personal Facts: User is a developer')
    end
    
    it 'returns empty string for no memories' do
      result = memory_service.format_memories_for_prompt([])
      expect(result).to eq('')
    end
  end
  
  describe '#extract_and_store_memories' do
    let(:messages) do
      [
        { role: 'user', content: 'Hi, my name is John' },
        { role: 'assistant', content: 'Nice to meet you John!' }
      ]
    end
    
    it 'processes memories in background thread' do
      allow(memory_service).to receive(:extract_memories_async)
      
      memory_service.extract_and_store_memories(messages, 'Hello John!')
      
      expect(memory_service).to have_received(:extract_memories_async)
    end
    
    it 'caches conversation hash to prevent duplicate processing' do
      allow(memory_service).to receive(:extract_memories_async)
      
      # First call
      memory_service.extract_and_store_memories(messages, 'Hello!')
      
      # Second call should be cached
      memory_service.extract_and_store_memories(messages, 'Hello!')
      
      expect(memory_service).to have_received(:extract_memories_async).once
    end
  end
  
  describe '#clear_memories' do
    before do
      # Create test memory files
      user_data = { 'memories' => [{ 'content' => 'test user memory' }] }
      session_data = { 'memories' => [{ 'content' => 'test session memory' }] }
      
      File.write('tmp/test_memories/user_test_user.json', user_data.to_json)
      File.write('tmp/test_memories/session_test_session.json', session_data.to_json)
    end
    
    it 'clears user memories' do
      expect(File.exist?('tmp/test_memories/user_test_user.json')).to be true
      
      memory_service.clear_user_memories
      
      expect(File.exist?('tmp/test_memories/user_test_user.json')).to be false
    end
    
    it 'clears session memories' do
      expect(File.exist?('tmp/test_memories/session_test_session.json')).to be true
      
      memory_service.clear_session_memories
      
      expect(File.exist?('tmp/test_memories/session_test_session.json')).to be false
    end
  end
  
  describe '#export_memories' do
    it 'exports memories with metadata' do
      result = memory_service.export_memories
      
      expect(result).to include(
        :user_memories,
        :session_memories,
        :exported_at,
        :version
      )
      expect(result[:version]).to eq(AiMemory::VERSION)
    end
  end
end
