# AiMemory

[![Gem Version](https://badge.fury.io/rb/ai_memory.svg)](https://badge.fury.io/rb/ai_memory)
[![Build Status](https://github.com/princetechs/ai_memory/workflows/CI/badge.svg)](https://github.com/princetechs/ai_memory/actions)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

Intelligent memory management system for AI chat applications with vector database support. Provides non-blocking memory extraction, semantic search, and automatic context injection for personalized AI conversations.

## 🚀 Features

- **Non-blocking memory extraction** - Chat responses are immediate, memory processing happens in background
- **Intelligent filtering** - Extracts only significant, factual information using AI
- **Vector database support** - Redis, PGVector, and Pinecone for semantic search
- **Automatic deduplication** - Prevents storing duplicate or similar memories
- **Pluggable architecture** - Easy to extend with custom extractors and adapters
- **Rails integration** - Seamless integration with Rails applications

## 📦 Installation

Add this line to your application's Gemfile:

```ruby
gem 'ai_memory'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ai_memory
```

## 🚀 Quick Start

### Rails Integration

1. **Generate configuration:**
```bash
rails generate ai_memory:install
```

2. **Configure environment variables:**
```bash
# Required
export OAI_ACCESS_TOKEN=your-openai-api-key

# Optional: Choose one vector database
export REDIS_VECTOR_ENABLED=true
export REDIS_URL=redis://localhost:6379
```

3. **Use in your application:**
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

### Standalone Usage

```ruby
require 'ai_memory'

# Configure the gem
AiMemory.configure do |config|
  config.openai_api_key = 'your-openai-api-key'
  config.storage_path = '/path/to/memories'
  config.redis_enabled = true
  config.redis_url = 'redis://localhost:6379'
end

# Use the memory service
memory_service = AiMemory::MemoryService.new(
  user_id: 'user_123',
  session_id: 'session_456'
)

# Extract memories from conversation
messages = [
  { role: 'user', content: 'Hi, my name is John and I love pizza' },
  { role: 'assistant', content: 'Nice to meet you John!' }
]

memory_service.extract_and_store_memories(messages, 'Nice to meet you John!')

# Get relevant memories
relevant_memories = memory_service.get_relevant_memories(
  query: 'What food do I like?',
  limit: 5
)
```

## 🔧 Configuration

### Basic Configuration
```ruby
AiMemory.configure do |config|
  # Storage settings
  config.storage_path = "storage/memories"
  config.max_user_memories = 100
  config.max_session_memories = 30
  config.similarity_threshold = 0.7
  
  # AI settings
  config.openai_api_key = ENV['OPENAI_API_KEY']
  config.embedding_model = "text-embedding-ada-002"
  config.extraction_temperature = 0.1
end
```

### Vector Database Configuration

#### Redis
```ruby
config.redis_enabled = true
config.redis_url = 'redis://localhost:6379'
config.redis_index_name = 'memory_vectors'
```

#### PostgreSQL with PGVector
```ruby
config.pgvector_enabled = true
config.pgvector_table_name = 'memory_embeddings'
# Uses DATABASE_URL or ActiveRecord connection
```

#### Pinecone
```ruby
config.pinecone_enabled = true
config.pinecone_api_key = 'your-pinecone-key'
config.pinecone_environment = 'your-environment'
config.pinecone_index_name = 'memory-index'
```

## 🎯 Memory Categories

The system automatically categorizes memories into:

- **Personal Facts**: Name, age, location, occupation, family
- **Preferences**: Likes, dislikes, hobbies, interests
- **Goals**: Short-term and long-term objectives
- **Events**: Important milestones or occurrences
- **Skills**: Expertise and abilities
- **Projects**: Current activities and work

## 📊 API Reference

### Core Methods

#### `extract_and_store_memories(messages, ai_response)`
Extracts and stores memories from conversation in background thread.

#### `get_relevant_memories(query:, limit:, use_vector_search:)`
Retrieves relevant memories with optional vector search.

#### `search_similar_memories(query, limit)`
Performs semantic similarity search using vector embeddings.

#### `format_memories_for_prompt(memories)`
Formats memories for AI prompt injection.

#### `get_memory_stats`
Returns comprehensive memory statistics.

#### `clear_user_memories` / `clear_session_memories`
Clears stored memories.

#### `export_memories` / `import_memories(data)`
Export/import memory data.

## 🏗 Architecture

### Pluggable Components

```
AiMemory/
├── MemoryService           # Main service orchestrator
├── Extractors/
│   ├── BaseExtractor      # Abstract extractor interface
│   └── OpenaiExtractor    # OpenAI-based memory extraction
├── VectorAdapters/
│   ├── BaseAdapter        # Abstract vector DB interface
│   ├── RedisAdapter       # Redis vector storage
│   ├── PgvectorAdapter    # PostgreSQL with pgvector
│   └── PineconeAdapter    # Pinecone cloud vector DB
└── Storage/
    └── JsonStorage        # JSON file storage
```

### Extending the Gem

#### Custom Extractor
```ruby
class CustomExtractor < AiMemory::Extractors::BaseExtractor
  def extract_memories(conversation_text)
    # Your custom extraction logic
    [
      {
        "content" => "extracted information",
        "category" => "custom_category",
        "importance" => "high",
        "type" => "user"
      }
    ]
  end
end

# Use custom extractor
memory_service.instance_variable_set(:@extractor, CustomExtractor.new(config))
```

#### Custom Vector Adapter
```ruby
class CustomVectorAdapter < AiMemory::VectorAdapters::BaseAdapter
  def available?
    # Check if your vector DB is available
  end
  
  def store_memory(memory, user_id, session_id)
    # Store memory in your vector database
  end
  
  def search_similar(query, limit, user_id:)
    # Search for similar memories
  end
end
```

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/ai_memory/memory_service_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

## 🚀 Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

### Development Commands
```bash
# Install dependencies
bin/setup

# Run tests
bundle exec rake spec

# Run RuboCop
bundle exec rubocop

# Generate documentation
bundle exec yard doc

# Build gem
bundle exec rake build

# Install locally
bundle exec rake install
```

## 📈 Performance

### Benchmarks
- **Memory Extraction**: ~2-3 seconds (background, non-blocking)
- **Memory Retrieval**: <100ms for JSON, <50ms for vector search
- **Vector Search**: Redis <10ms, PGVector 10-50ms, Pinecone 20-100ms
- **Storage Efficiency**: Automatic deduplication and compression

### Memory Limits
- **User Memories**: 100 (configurable)
- **Session Memories**: 30 (configurable)
- **Automatic cleanup** based on importance and recency

## 🔍 Monitoring

The gem provides comprehensive logging:

```ruby
# Enable detailed logging
AiMemory.configure do |config|
  config.logger = Logger.new($stdout, level: Logger::INFO)
end
```

Log messages include:
- Memory extraction progress
- Vector database operations
- Performance metrics
- Error handling

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Run RuboCop (`bundle exec rubocop`)
6. Commit your changes (`git commit -am 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Create a Pull Request

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 🙏 Acknowledgments

- **mem0ai** - Inspiration for memory architecture design
- **OpenAI** - Powerful language models for extraction and embeddings
- **Ruby community** - For excellent gems and best practices

## 📞 Support

- 📖 [Documentation](https://rubydoc.info/gems/ai_memory)
- 🐛 [Issues](https://github.com/princetechs/ai_memory/issues)
- 💬 [Discussions](https://github.com/princetechs/ai_memory/discussions)

---

**Built with ❤️ for intelligent, personalized AI conversations**
