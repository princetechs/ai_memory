# Rails Integration Guide

This guide shows how to integrate the AiMemory gem into your Rails application.

## Installation

Add to your Gemfile:
```ruby
gem 'ai_memory', path: '../ai_memory'  # For local development
# gem 'ai_memory'  # For published gem
```

Run the installer:
```bash
bundle install
rails generate ai_memory:install
```

## Configuration

Update `config/initializers/ai_memory.rb`:
```ruby
AiMemory.configure do |config|
  config.openai_api_key = Rails.application.credentials.openai_api_key
  config.storage_path = Rails.root.join('storage', 'ai_memory')
  
  # Enable Redis vector search (optional)
  config.redis_enabled = true
  config.redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379'
  
  # Configure memory limits
  config.max_user_memories = 100
  config.max_session_memories = 30
end
```

## Usage in Controllers

Replace existing memory service calls:

```ruby
# In MessagesController
class MessagesController < ApplicationController
  def create
    # Initialize memory service
    memory_service = AiMemory::MemoryService.new(
      user_id: current_user.id,
      session_id: session.id
    )
    
    # Get relevant memories for context
    memories = memory_service.get_relevant_memories(params[:message])
    context = memory_service.format_memories_for_prompt(memories)
    
    # Generate AI response with memory context
    response = generate_ai_response(params[:message], context)
    
    # Extract and store new memories asynchronously
    conversation = [
      { role: 'user', content: params[:message] },
      { role: 'assistant', content: response }
    ]
    memory_service.extract_and_store_memories(conversation, response)
    
    render json: { response: response }
  end
end
```

## Memory Management

```ruby
# In MemoriesController
class MemoriesController < ApplicationController
  def index
    memory_service = AiMemory::MemoryService.new(
      user_id: current_user.id,
      session_id: session.id
    )
    
    @stats = memory_service.get_memory_stats
    @user_memories = memory_service.get_user_memories
    @session_memories = memory_service.get_session_memories
  end
  
  def clear_user
    memory_service = AiMemory::MemoryService.new(
      user_id: current_user.id,
      session_id: session.id
    )
    memory_service.clear_memories(type: 'user')
    redirect_to memories_path
  end
end
```

## Environment Variables

Set these in your `.env` file:
```bash
# Required
OAI_ACCESS_TOKEN=your_openai_api_key

# Optional - Redis Vector Search
REDIS_VECTOR_ENABLED=true
REDIS_URL=redis://localhost:6379
REDIS_INDEX_NAME=ai_memories

# Optional - PGVector
PGVECTOR_ENABLED=false
PGVECTOR_TABLE=ai_memories

# Optional - Pinecone
PINECONE_ENABLED=false
PINECONE_API_KEY=your_pinecone_key
PINECONE_ENVIRONMENT=your_environment
PINECONE_INDEX_NAME=ai-memories
```

## Removing Legacy Code

After integration, you can safely remove:
- `app/services/memory/memory_enhanced_chat_service.rb`
- `app/services/memory/memory_extraction_service.rb`
- `app/services/memory/memory_storage_service.rb`
- `app/services/memory/memory_manager_service.rb`
- `config/initializers/vector_memory.rb` (if using gem's config)

## Testing Integration

Test the integration:
```ruby
# In Rails console
memory_service = AiMemory::MemoryService.new(user_id: 1, session_id: 'test')
puts memory_service.get_memory_stats
```

## Performance Considerations

- Memory extraction runs in background threads
- Vector search provides faster retrieval than JSON scanning
- Configure memory limits based on your application needs
- Monitor storage directory size in production
