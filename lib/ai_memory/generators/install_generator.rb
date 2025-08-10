# frozen_string_literal: true

require 'rails/generators'

module AiMemory
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Install AiMemory configuration and initializer"
      
      def create_initializer
        template 'initializer.rb', 'config/initializers/ai_memory.rb'
      end
      
      def create_storage_directory
        empty_directory 'storage/memories'
        create_file 'storage/memories/.keep'
      end
      
      def show_readme
        readme 'INSTALL.md' if File.exist?(File.expand_path('templates/INSTALL.md', __dir__))
      end
      
      private
      
      def app_name
        Rails.application.class.module_parent_name.underscore
      end
    end
  end
end
