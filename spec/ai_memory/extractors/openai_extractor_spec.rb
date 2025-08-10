require 'spec_helper'

RSpec.describe AiMemory::Extractors::OpenaiExtractor do
  let(:config) do
    AiMemory::Configuration.new.tap do |c|
      c.openai_api_key = 'test-key'
      c.extraction_temperature = 0.1
      c.extraction_max_tokens = 800
    end
  end
  
  let(:extractor) { described_class.new(config) }
  
  describe '#extract_memories' do
    let(:conversation) do
      [
        { role: 'user', content: 'Hi, my name is John and I love pizza' },
        { role: 'assistant', content: 'Nice to meet you John! Pizza is delicious.' }
      ]
    end
    
    context 'when OpenAI responds successfully' do
      before do
        mock_client = double('openai_client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        
        mock_response = {
          'choices' => [
            {
              'message' => {
                'content' => JSON.generate({
                  'memories' => [
                    {
                      'content' => 'User name is John',
                      'category' => 'personal_facts',
                      'importance' => 'high'
                    },
                    {
                      'content' => 'User likes pizza',
                      'category' => 'preferences',
                      'importance' => 'medium'
                    }
                  ]
                })
              }
            }
          ]
        }
        
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end
      
      it 'extracts memories from conversation' do
        memories = extractor.extract_memories(conversation)
        
        expect(memories).to be_an(Array)
        expect(memories.length).to eq(2)
        expect(memories.first['content']).to eq('User name is John')
        expect(memories.first['category']).to eq('personal_facts')
      end
    end
    
    context 'when OpenAI API fails' do
      before do
        allow(OpenAI::Client).to receive(:new).and_raise(StandardError.new('API Error'))
      end
      
      it 'returns empty array on error' do
        memories = extractor.extract_memories(conversation)
        expect(memories).to eq([])
      end
    end
    
    context 'when response is invalid JSON' do
      before do
        mock_client = double('openai_client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        
        mock_response = {
          'choices' => [
            { 'message' => { 'content' => 'invalid json' } }
          ]
        }
        
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end
      
      it 'returns empty array for invalid JSON' do
        memories = extractor.extract_memories(conversation)
        expect(memories).to eq([])
      end
    end
  end
  
  describe '#generate_embedding' do
    context 'when OpenAI responds successfully' do
      before do
        mock_client = double('openai_client')
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        
        mock_response = {
          'data' => [
            { 'embedding' => [0.1, 0.2, 0.3] }
          ]
        }
        
        allow(mock_client).to receive(:embeddings).and_return(mock_response)
      end
      
      it 'generates embedding for text' do
        embedding = extractor.generate_embedding('test text')
        expect(embedding).to eq([0.1, 0.2, 0.3])
      end
    end
    
    context 'when OpenAI API fails' do
      before do
        allow(OpenAI::Client).to receive(:new).and_raise(StandardError.new('API Error'))
      end
      
      it 'returns nil on error' do
        embedding = extractor.generate_embedding('test text')
        expect(embedding).to be_nil
      end
    end
  end
end
