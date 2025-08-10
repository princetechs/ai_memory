# frozen_string_literal: true

module AiMemory
  class Railtie < Rails::Railtie
    initializer "ai_memory.configure" do |app|
      # Auto-configure from Rails environment
      AiMemory.configure do |config|
        config.storage_path = Rails.root.join("storage", "memories").to_s
        config.logger = Rails.logger
        
        # Load configuration from Rails credentials or environment
        if Rails.application.credentials.ai_memory
          credentials = Rails.application.credentials.ai_memory
          config.openai_api_key ||= credentials[:openai_api_key]
          config.redis_url ||= credentials[:redis_url]
          config.pinecone_api_key ||= credentials[:pinecone_api_key]
          config.pinecone_environment ||= credentials[:pinecone_environment]
        end
      end
    end
    
    generators do
      require_relative "generators/install_generator"
    end
  end
end
