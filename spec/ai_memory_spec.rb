# frozen_string_literal: true

RSpec.describe AiMemory do
  it "has a version number" do
    expect(AiMemory::VERSION).not_to be nil
  end

  it "can be configured" do
    AiMemory.configure do |config|
      config.openai_api_key = 'test-key'
      config.storage_path = 'test/path'
    end
    
    expect(AiMemory.configuration.openai_api_key).to eq('test-key')
    expect(AiMemory.configuration.storage_path).to eq('test/path')
  end
  
  it "can reset configuration" do
    AiMemory.configure { |config| config.openai_api_key = 'test' }
    AiMemory.reset_configuration!
    
    expect(AiMemory.configuration.openai_api_key).to eq(ENV['OAI_ACCESS_TOKEN'])
  end
end
