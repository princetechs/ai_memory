# frozen_string_literal: true

module AiMemory
  module Storage
    class JsonStorage
      attr_reader :service
      
      def initialize(service)
        @service = service
        @config = service.config
      end
      
      def store_user_memories(memories)
        return unless @service.user_id && memories.any?
        
        user_data = @service.send(:read_json_file, @service.send(:user_memory_file))
        user_data["memories"] ||= []
        user_data["last_updated"] = Time.now.iso8601
        
        # Add new memories with deduplication
        memories.each do |memory|
          unless duplicate_memory?(user_data["memories"], memory)
            user_data["memories"] << memory
          end
        end
        
        # Keep only most important memories
        user_data["memories"] = user_data["memories"]
          .sort_by { |m| [-importance_score(m["importance"]), -Time.parse(m["timestamp"]).to_i] }
          .first(@config.max_user_memories)
        
        @service.send(:write_json_file, @service.send(:user_memory_file), user_data)
      end
      
      def store_session_memories(memories)
        return unless @service.session_id && memories.any?
        
        session_data = @service.send(:read_json_file, @service.send(:session_memory_file))
        session_data["memories"] ||= []
        session_data["last_updated"] = Time.now.iso8601
        
        # Add new memories
        memories.each do |memory|
          session_data["memories"] << memory
        end
        
        # Keep only recent memories
        session_data["memories"] = session_data["memories"].last(@config.max_session_memories)
        
        @service.send(:write_json_file, @service.send(:session_memory_file), session_data)
      end
      
      def get_user_memories(query_context = nil)
        return [] unless @service.user_id && File.exist?(@service.send(:user_memory_file))
        
        user_data = @service.send(:read_json_file, @service.send(:user_memory_file))
        memories = user_data["memories"] || []
        
        query_context ? filter_memories_by_relevance(memories, query_context) : memories
      end
      
      def get_session_memories(query_context = nil)
        return [] unless @service.session_id && File.exist?(@service.send(:session_memory_file))
        
        session_data = @service.send(:read_json_file, @service.send(:session_memory_file))
        memories = session_data["memories"] || []
        
        query_context ? filter_memories_by_relevance(memories, query_context) : memories
      end
      
      def clear_user_memories
        return unless @service.user_id
        
        user_file = @service.send(:user_memory_file)
        File.delete(user_file) if File.exist?(user_file)
      end
      
      def clear_session_memories
        return unless @service.session_id
        
        session_file = @service.send(:session_memory_file)
        File.delete(session_file) if File.exist?(session_file)
      end
      
      def count_user_memories
        return 0 unless @service.user_id && File.exist?(@service.send(:user_memory_file))
        
        user_data = @service.send(:read_json_file, @service.send(:user_memory_file))
        (user_data["memories"] || []).count
      end
      
      def count_session_memories
        return 0 unless @service.session_id && File.exist?(@service.send(:session_memory_file))
        
        session_data = @service.send(:read_json_file, @service.send(:session_memory_file))
        (session_data["memories"] || []).count
      end
      
      private
      
      def filter_memories_by_relevance(memories, query_context)
        return memories if query_context.blank?
        
        query_keywords = query_context.downcase.split(/\W+/).reject(&:empty?)
        return memories if query_keywords.empty?
        
        relevant_memories = memories.select do |memory|
          content_words = memory["content"].downcase.split(/\W+/)
          (query_keywords & content_words).any?
        end
        
        relevant_memories.any? ? relevant_memories : memories.first(5)
      end
      
      def duplicate_memory?(existing_memories, new_memory)
        existing_memories.any? do |existing|
          similarity = calculate_similarity(existing["content"], new_memory["content"])
          similarity > @config.similarity_threshold
        end
      end
      
      def calculate_similarity(text1, text2)
        words1 = text1.downcase.split(/\W+/)
        words2 = text2.downcase.split(/\W+/)
        
        return 0 if words1.empty? || words2.empty?
        
        common_words = words1 & words2
        total_words = (words1 + words2).uniq.length
        
        common_words.length.to_f / total_words
      end
      
      def importance_score(importance)
        case importance
        when "high" then 3
        when "medium" then 2
        when "low" then 1
        else 1
        end
      end
    end
  end
end
