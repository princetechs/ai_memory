# frozen_string_literal: true

require 'securerandom'

module AiMemory
  class MemoryService < BaseService
    attr_reader :vector_adapter, :extractor, :storage
    
    def initialize(user_id:, session_id:, config: nil)
      super(user_id: user_id, session_id: session_id, config: config)
      
      @vector_adapter = initialize_vector_adapter
      @extractor = initialize_extractor
      @storage = AiMemory::Storage::JsonStorage.new(self)
      @extraction_cache = {}
    end
    
    # Main API methods
    def extract_and_store_memories(messages, ai_response)
      conversation_hash = generate_conversation_hash(messages, ai_response)
      return if @extraction_cache[conversation_hash]
      
      @extraction_cache[conversation_hash] = true
      extract_memories_async(messages, ai_response)
    end
    
    # Store pre-extracted memories directly
    # @param memories [Array<Hash>] Array of memory objects with content, category, importance, and type
    def store_memories(memories)
      return if memories.nil? || memories.empty?
      
      user_memories = []
      session_memories = []
      
      memories.each do |memory|
        # Convert string keys to symbols if needed
        mem = memory.transform_keys(&:to_sym) if memory.keys.first.is_a?(String)
        mem ||= memory
        
        # Add timestamps and IDs
        mem[:created_at] = Time.now.iso8601
        mem[:id] = SecureRandom.uuid
        
        if mem[:type].to_s == 'user'
          user_memories << mem
        else
          session_memories << mem
        end
      end
      
      # Store memories in appropriate storage
      @storage.store_user_memories(user_memories) if user_memories.any?
      @storage.store_session_memories(session_memories) if session_memories.any?
      
      # Store in vector database if available
      store_in_vector_db(user_memories + session_memories) if @vector_adapter&.available?
      
      log_info("Stored #{user_memories.count} user memories and #{session_memories.count} session memories")
    end
    
    def get_relevant_memories(query: nil, limit: 10, use_vector_search: true)
      memories = []
      
      if use_vector_search && @vector_adapter&.available?
        vector_memories = search_similar_memories(query, limit / 2)
        memories.concat(vector_memories)
      end
      
      # Get keyword-based memories
      keyword_memories = get_keyword_memories(query, limit - memories.count)
      memories.concat(keyword_memories)
      
      memories.uniq { |m| m['content'] || m[:content] }.first(limit)
    end
    
    def search_similar_memories(query, limit = 5)
      return [] unless @vector_adapter&.available? && query
      
      @vector_adapter.search_similar(query, limit, user_id: @user_id)
    rescue => e
      log_error("Vector search failed: #{e.message}")
      []
    end
    
    def format_memories_for_prompt(memories)
      return "" if memories.empty?
      
      formatted = ["=== MEMORY CONTEXT ==="]
      memories.each do |memory|
        content = memory['content'] || memory[:content]
        category = (memory['category'] || memory[:category]) || 'general'
        category = category.split('_').map(&:capitalize).join(' ')
        formatted << "#{category}: #{content}"
      end
      
      formatted.join("\n")
    end
    
    def get_memory_stats
      {
        user_memories: @storage.get_user_memories.count,
        session_memories: @storage.get_session_memories.count,
        total_memories: @storage.get_user_memories.count + @storage.get_session_memories.count,
        vector_db_enabled: @vector_adapter&.available? || false,
        vector_db_type: @vector_adapter&.class&.name&.split('::')&.last&.gsub('Adapter', '')&.downcase || 'none',
        last_extraction: @last_extraction_time
      }
    end
    
    def get_user_memories
      @storage.get_user_memories
    end
    
    def get_session_memories
      @storage.get_session_memories
    end
    
    def clear_memories(type:)
      case type.to_s
      when 'user'
        clear_user_memories
      when 'session'
        clear_session_memories
      else
        raise ArgumentError, "Invalid memory type: #{type}. Use 'user' or 'session'"
      end
    end
    
    def clear_session_memories
      @storage.clear_session_memories
      @vector_adapter&.clear_session_vectors(@session_id) if @vector_adapter&.available?
      log_info("Cleared session memories for session: #{@session_id}")
    end
    
    def clear_user_memories
      @storage.clear_user_memories
      @vector_adapter&.clear_user_vectors(@user_id) if @vector_adapter&.available?
      log_info("Cleared user memories for user: #{@user_id}")
    end
    
    def export_memories
      {
        user_memories: @storage.get_user_memories,
        session_memories: @storage.get_session_memories,
        exported_at: Time.now.iso8601,
        version: AiMemory::VERSION
      }
    end
    
    def import_memories(data)
      return false unless data.is_a?(Hash)
      
      user_memories = data['user_memories'] || []
      session_memories = data['session_memories'] || []
      
      @storage.store_user_memories(user_memories) if user_memories.any?
      @storage.store_session_memories(session_memories) if session_memories.any?
      
      # Store in vector database if available
      all_memories = user_memories + session_memories
      store_in_vector_db(all_memories) if @vector_adapter&.available?
      
      log_info("Imported #{user_memories.count} user memories, #{session_memories.count} session memories")
      true
    rescue => e
      log_error("Failed to import memories: #{e.message}")
      false
    end
    
    private
    
    def initialize_vector_adapter
      if @config.redis_enabled
        AiMemory::VectorAdapters::RedisAdapter.new(@config)
      elsif @config.pgvector_enabled
        AiMemory::VectorAdapters::PgvectorAdapter.new(@config)
      elsif @config.pinecone_enabled
        AiMemory::VectorAdapters::PineconeAdapter.new(@config)
      end
    rescue => e
      log_warn("Failed to initialize vector adapter: #{e.message}")
      nil
    end
    
    def initialize_extractor
      AiMemory::Extractors::OpenaiExtractor.new(@config)
    rescue => e
      log_error("Failed to initialize extractor: #{e.message}")
      raise ConfigurationError, "Memory extractor initialization failed: #{e.message}"
    end
    
    def extract_memories_async(messages, ai_response)
      Thread.new do
        begin
          log_info("Starting memory extraction for user: #{@user_id}, session: #{@session_id}")
          
          # Prepare conversation for analysis
          full_conversation = messages + [{ role: 'assistant', content: ai_response }]
          conversation_text = format_conversation_for_analysis(full_conversation)
          
          # Skip extraction if conversation is too short or generic
          return if conversation_text.length < 50 || generic_conversation?(conversation_text)
          
          # Extract memories using the configured extractor
          # extracted_memories = @extractor.extract_memories(conversation_text)
          return if extracted_memories.empty?
          
          # Process and store memories
          process_extracted_memories(extracted_memories)
          @last_extraction_time = Time.current.iso8601
          
        rescue => e
          log_error("Memory extraction failed: #{e.message}")
        end
      end
    end
    
    def process_extracted_memories(memories)
      user_memories = []
      session_memories = []
      
      memories.each do |memory|
        next unless valid_memory?(memory)
        
        # Add current timestamp
        memory["timestamp"] = Time.now.iso8601
        memory["content"] = memory["content"].strip
        
        # Categorize by type and importance
        if memory["type"] == "user" || memory["importance"] == "high"
          user_memories << memory
        else
          session_memories << memory
        end
      end
      
      # Store in JSON storage
      @storage.store_user_memories(user_memories) if user_memories.any?
      @storage.store_session_memories(session_memories) if session_memories.any?
      
      # Store in vector database if available
      store_in_vector_db(user_memories + session_memories) if @vector_adapter&.available?
      
      log_info("Stored #{user_memories.count} user memories, #{session_memories.count} session memories")
    end
    
    def store_in_vector_db(memories)
      return unless @vector_adapter&.available? && memories.any?
      
      memories.each do |memory|
        @vector_adapter.store_memory(memory, @user_id, @session_id)
      end
    rescue => e
      log_error("Failed to store memories in vector database: #{e.message}")
    end
    
    def get_keyword_memories(query, limit)
      user_memories = @storage.get_user_memories(query)
      session_memories = @storage.get_session_memories(query)
      
      all_memories = (user_memories + session_memories)
        .sort_by { |m| [-importance_score(m["importance"]), -Time.parse(m["timestamp"]).to_i] }
      
      all_memories.first(limit)
    rescue => e
      log_error("Failed to get keyword memories: #{e.message}")
      []
    end
    
    def format_conversation_for_analysis(messages)
      messages.map do |msg|
        role = msg[:role].to_s.upcase
        content = msg[:content].to_s.strip
        "#{role}: #{content}"
      end.join("\n\n")
    end
    
    def generate_conversation_hash(messages, ai_response)
      content = messages.map { |m| m[:content] }.join + ai_response.to_s
      Digest::MD5.hexdigest(content)
    end
    
    def generic_conversation?(text)
      generic_patterns = [
        /^(hi|hello|hey|thanks|thank you|ok|okay|yes|no)$/i,
        /^(how are you|what's up|good morning|good afternoon)$/i
      ]
      
      generic_patterns.any? { |pattern| text.match?(pattern) }
    end
    
    def valid_memory?(memory)
      return false unless memory.is_a?(Hash)
      return false unless memory["content"]&.length&.> 10
      return false unless %w[personal_facts preferences goals events skills projects].include?(memory["category"])
      return false unless %w[high medium low].include?(memory["importance"])
      
      true
    end
    
    def importance_score(importance)
      case importance
      when "high" then 3
      when "medium" then 2
      when "low" then 1
      else 1
      end
    end
    
    def count_user_memories
      @storage.count_user_memories
    end
    
    def count_session_memories
      @storage.count_session_memories
    end
  end
end
