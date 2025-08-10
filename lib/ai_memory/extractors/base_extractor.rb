# frozen_string_literal: true

module AiMemory
  module Extractors
    class BaseExtractor
      attr_reader :config
      
      def initialize(config)
        @config = config
      end
      
      def extract_memories(conversation_text)
        raise NotImplementedError, "Subclasses must implement extract_memories method"
      end
      
      protected
      
      def log_info(message)
        @config.logger&.info("[AiMemory::Extractor] #{message}")
      end
      
      def log_error(message)
        @config.logger&.error("[AiMemory::Extractor] #{message}")
      end
    end
  end
end
