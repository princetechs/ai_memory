# frozen_string_literal: true

require 'json'
require 'digest'
require 'fileutils'

module AiMemory
  class BaseService
    attr_reader :user_id, :session_id, :config
    
    def initialize(user_id:, session_id:, config: nil)
      @user_id = user_id
      @session_id = session_id
      @config = config || AiMemory.configuration || AiMemory::Configuration.new
      @config.validate!
      
      ensure_storage_directory
    end
    
    protected
    
    def storage_directory
      @storage_directory ||= File.expand_path(@config.storage_path)
    end
    
    def user_memory_file
      File.join(storage_directory, "user_#{@user_id}.json")
    end
    
    def session_memory_file
      File.join(storage_directory, "session_#{@session_id}.json")
    end
    
    def ensure_storage_directory
      FileUtils.mkdir_p(storage_directory) unless Dir.exist?(storage_directory)
    end
    
    def read_json_file(file_path)
      return {} unless File.exist?(file_path)
      
      JSON.parse(File.read(file_path))
    rescue JSON::ParserError => e
      log_error("Failed to parse JSON file #{file_path}: #{e.message}")
      {}
    rescue => e
      log_error("Failed to read file #{file_path}: #{e.message}")
      {}
    end
    
    def write_json_file(file_path, data)
      File.write(file_path, JSON.pretty_generate(data))
      true
    rescue => e
      log_error("Failed to write JSON file #{file_path}: #{e.message}")
      false
    end
    
    def log_info(message)
      @config.logger&.info("[AiMemory] #{message}")
    end
    
    def log_error(message)
      @config.logger&.error("[AiMemory] #{message}")
    end
    
    def log_warn(message)
      @config.logger&.warn("[AiMemory] #{message}")
    end
  end
end
