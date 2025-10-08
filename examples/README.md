# ToolForge Examples

This directory contains practical examples of ToolForge usage, demonstrating various features and patterns.

## Examples

### 1. Docker Copy Tool (`docker_copy_tool.rb`)
Demonstrates:
- **Class helper methods** for utility functions (`add_to_tar`, `validate_container_id`)
- **Instance helper methods** for result formatting
- **Parameter validation** and error handling
- **Complex return values** with structured data

**Key Features:**
- Container ID validation
- Tar archive operations simulation
- File existence checking
- Comprehensive error handling

### 2. File Processor Tool (`file_processor_tool.rb`)
Demonstrates:
- **Multiple instance helper methods** for different concerns
- **Array parameters** for multiple operations
- **Complex text processing** with various transformations
- **Multiple output formats** (JSON, YAML, text)
- **Preserve original data** option

**Key Features:**
- Text analysis (word count, line count, etc.)
- Text transformations (case changes, reversals, etc.)
- Flexible output formatting
- Operation chaining

## Running Examples

To run these examples:

```bash
# From the project root
ruby examples/docker_copy_tool.rb
ruby examples/file_processor_tool.rb
```

## Creating Your Own Tools

Use these examples as templates for your own tools:

1. **Start with a clear purpose** - what does your tool do?
2. **Define parameters** - what inputs does it need?
3. **Break down complex logic** into helper methods
4. **Choose the right helper type**:
   - Use `helper` for instance methods that work with tool data
   - Use `class_helper` for utility functions and static operations
5. **Handle errors gracefully** - return structured error information
6. **Consider output format** - how will users consume the results?

## Integration Examples

### With RubyLLM

```ruby
require 'ruby_llm'
require_relative 'docker_copy_tool'

# Convert to RubyLLM format
ruby_llm_tool = docker_copy_tool.to_ruby_llm_tool

# Use with RubyLLM framework
llm = RubyLLM::Client.new
llm.add_tool(ruby_llm_tool)
```

### With MCP

```ruby
require 'mcp'
require_relative 'file_processor_tool'

# Convert to MCP format
mcp_tool = file_processor_tool.to_mcp_tool

# Use with MCP server
server = MCP::Server.new
server.add_tool(mcp_tool)
```

## Best Practices Demonstrated

1. **Clear parameter documentation** - each parameter has a description
2. **Sensible defaults** - optional parameters have reasonable defaults
3. **Input validation** - check inputs before processing
4. **Error handling** - graceful failure with informative messages
5. **Structured outputs** - consistent, parseable return values
6. **Helper method organization** - logical separation of concerns
7. **Type safety** - appropriate parameter types for inputs
