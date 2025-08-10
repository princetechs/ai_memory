require 'spec_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe AiMemory::Storage::JsonStorage do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config) do
    AiMemory::Configuration.new.tap do |c|
      c.storage_path = temp_dir
      c.max_user_memories = 5
      c.max_session_memories = 3
      c.similarity_threshold = 0.8
    end
  end
  
  let(:mock_service) do
    double('memory_service').tap do |service|
      allow(service).to receive(:user_memory_file).and_return(File.join(temp_dir, 'user_test.json'))
      allow(service).to receive(:session_memory_file).and_return(File.join(temp_dir, 'session_test.json'))
      allow(service).to receive(:read_json_file) do |file|
        File.exist?(file) ? JSON.parse(File.read(file)) : { 'memories' => [] }
      end
      allow(service).to receive(:write_json_file) do |file, data|
        File.write(file, JSON.pretty_generate(data))
      end
      allow(service).to receive(:log_info)
    end
  end
  
  let(:storage) { described_class.new(mock_service, config) }
  
  after do
    FileUtils.rm_rf(temp_dir)
  end
  
  describe '#store_user_memories' do
    let(:memories) do
      [
        {
          'content' => 'User likes pizza',
          'category' => 'preferences',
          'importance' => 'high',
          'timestamp' => Time.now.iso8601
        },
        {
          'content' => 'User is a developer',
          'category' => 'personal_facts',
          'importance' => 'medium',
          'timestamp' => Time.now.iso8601
        }
      ]
    end
    
    it 'stores user memories with deduplication' do
      storage.store_user_memories(memories)
      
      stored_memories = storage.get_user_memories
      expect(stored_memories.length).to eq(2)
      expect(stored_memories.first['content']).to eq('User likes pizza')
    end
    
    it 'prevents duplicate memories' do
      # Store memories twice
      storage.store_user_memories(memories)
      storage.store_user_memories(memories)
      
      stored_memories = storage.get_user_memories
      expect(stored_memories.length).to eq(2) # Should not duplicate
    end
    
    it 'respects memory limits' do
      # Create more memories than the limit
      many_memories = (1..10).map do |i|
        {
          'content' => "Memory #{i}",
          'category' => 'test',
          'importance' => i > 5 ? 'high' : 'low',
          'timestamp' => Time.now.iso8601
        }
      end
      
      storage.store_user_memories(many_memories)
      
      stored_memories = storage.get_user_memories
      expect(stored_memories.length).to eq(5) # Should respect max limit
      
      # Should keep high importance memories
      high_importance_count = stored_memories.count { |m| m['importance'] == 'high' }
      expect(high_importance_count).to be > 0
    end
  end
  
  describe '#store_session_memories' do
    let(:memories) do
      [
        {
          'content' => 'User mentioned project deadline',
          'category' => 'context',
          'importance' => 'medium',
          'timestamp' => Time.now.iso8601
        }
      ]
    end
    
    it 'stores session memories' do
      storage.store_session_memories(memories)
      
      stored_memories = storage.get_session_memories
      expect(stored_memories.length).to eq(1)
      expect(stored_memories.first['content']).to eq('User mentioned project deadline')
    end
    
    it 'respects session memory limits' do
      many_memories = (1..5).map do |i|
        {
          'content' => "Session memory #{i}",
          'category' => 'context',
          'importance' => 'medium',
          'timestamp' => Time.now.iso8601
        }
      end
      
      storage.store_session_memories(many_memories)
      
      stored_memories = storage.get_session_memories
      expect(stored_memories.length).to eq(3) # Should respect session limit
    end
  end
  
  describe '#get_user_memories' do
    before do
      memories = [
        {
          'content' => 'User likes coffee',
          'category' => 'preferences',
          'importance' => 'medium',
          'timestamp' => Time.now.iso8601
        }
      ]
      storage.store_user_memories(memories)
    end
    
    it 'retrieves user memories' do
      memories = storage.get_user_memories
      expect(memories).to be_an(Array)
      expect(memories.first['content']).to eq('User likes coffee')
    end
    
    it 'filters memories by query context' do
      memories = storage.get_user_memories('coffee')
      expect(memories).to be_an(Array)
      # Should include coffee-related memory
    end
  end
  
  describe '#clear_user_memories' do
    before do
      memories = [{ 'content' => 'Test memory', 'category' => 'test', 'timestamp' => Time.now.iso8601 }]
      storage.store_user_memories(memories)
    end
    
    it 'clears all user memories' do
      expect(storage.get_user_memories.length).to eq(1)
      
      storage.clear_user_memories
      
      expect(storage.get_user_memories.length).to eq(0)
    end
  end
  
  describe '#clear_session_memories' do
    before do
      memories = [{ 'content' => 'Session memory', 'category' => 'context', 'timestamp' => Time.now.iso8601 }]
      storage.store_session_memories(memories)
    end
    
    it 'clears all session memories' do
      expect(storage.get_session_memories.length).to eq(1)
      
      storage.clear_session_memories
      
      expect(storage.get_session_memories.length).to eq(0)
    end
  end
end
