# Contributing to AiMemory

Thank you for your interest in contributing to AiMemory! This guide will help you get started.

## Development Setup

1. Fork and clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Run tests:
   ```bash
   bundle exec rspec
   ```
4. Run linting:
   ```bash
   bundle exec rubocop
   ```

## Testing

- Write tests for all new features
- Ensure all tests pass before submitting
- Test coverage should be maintained above 90%

## Code Style

- Follow Ruby style guidelines
- Use RuboCop for linting
- Write clear, descriptive commit messages

## Submitting Changes

1. Create a feature branch
2. Make your changes with tests
3. Ensure all tests pass
4. Submit a pull request with clear description

## Vector Database Testing

For testing vector database adapters:
- Redis: Requires Redis server with RediSearch
- PGVector: Requires PostgreSQL with pgvector extension
- Pinecone: Requires API key and index setup

## Documentation

- Update README.md for new features
- Add YARD documentation for public methods
- Update CHANGELOG.md for releases
