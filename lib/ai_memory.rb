# frozen_string_literal: true

require_relative "ai_memory/version"
require_relative "ai_memory/configuration"
require_relative "ai_memory/base_service"
require_relative "ai_memory/memory_service"
require_relative "ai_memory/vector_adapters/base_adapter"
require_relative "ai_memory/vector_adapters/redis_adapter"
require_relative "ai_memory/vector_adapters/pgvector_adapter"
require_relative "ai_memory/vector_adapters/pinecone_adapter"
require_relative "ai_memory/extractors/base_extractor"
require_relative "ai_memory/extractors/openai_extractor"
require_relative "ai_memory/storage/json_storage"
require_relative "ai_memory/railtie" if defined?(Rails)

module AiMemory
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class VectorDatabaseError < Error; end
  class ExtractionError < Error; end
  
  class << self
    attr_accessor :configuration
    
    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end
    
    def reset_configuration!
      self.configuration = Configuration.new
    end
  end
end
