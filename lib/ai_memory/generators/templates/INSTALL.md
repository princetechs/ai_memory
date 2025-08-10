# AiMemory Installation Complete!

## Next Steps

### 1. Configure Environment Variables
Add these to your `.env` file or environment:

```bash
# Required: OpenAI API Key
OAI_ACCESS_TOKEN=your-openai-api-key

# Optional: Choose ONE vector database
# REDIS_VECTOR_ENABLED=true
# REDIS_URL=redis://localhost:6379

# OR
# PGVECTOR_ENABLED=true
# DATABASE_URL=postgresql://user:pass@localhost/db

# OR  
# PINECONE_ENABLED=true
# PINECONE_API_KEY=your-pinecone-key
# PINECONE_ENVIRONMENT=your-pinecone-env
```

### 2. Basic Usage

```ruby
# Initialize memory service
memory_service = AiMemory::MemoryService.new(
  user_id: current_user.id,
  session_id: session.id
)

# Get relevant memories for AI context
memories = memory_service.get_relevant_memories(
  query: user_message,
  limit: 10
)

# Format for AI prompt
context = memory_service.format_memories_for_prompt(memories)

# Extract and store memories (non-blocking)
memory_service.extract_and_store_memories(messages, ai_response)
```

### 3. Check Configuration
```ruby
# In Rails console
AiMemory.configuration.validate!
puts AiMemory.configuration.vector_db_enabled?
```

For more information, visit: https://github.com/princetechs/ai_memory
