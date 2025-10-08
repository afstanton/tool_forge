# ToolForge

ToolForge is a Ruby gem that provides a unified DSL for defining tools that can be converted to both [RubyLLM](https://github.com/ruby-llm/ruby-llm) and [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) formats. Write your tool once, use it anywhere.

## Features

- 🎯 **Unified DSL**: Define tools once, convert to multiple formats
- 🔧 **Helper Methods**: Support for both instance and class helper methods
- 📊 **Type Safety**: Parameter validation and type conversion
- 🚀 **Framework Agnostic**: Works with RubyLLM and MCP frameworks
- 📝 **Clean API**: Intuitive, Ruby-like syntax

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add tool_forge
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install tool_forge
```

## Quick Start

```ruby
require 'tool_forge'

# Define a tool
tool = ToolForge.define(:greet_user) do
  description 'Greets a user with a personalized message'

  param :name, type: :string, description: 'User name'
  param :greeting, type: :string, description: 'Greeting style',
        required: false, default: 'Hello'

  execute do |name:, greeting:|
    "#{greeting}, #{name}! Welcome to ToolForge!"
  end
end

# Convert to RubyLLM format
ruby_llm_tool = tool.to_ruby_llm_tool
instance = ruby_llm_tool.new
result = instance.execute(name: 'Alice')
#=> "Hello, Alice! Welcome to ToolForge!"

# Convert to MCP format
mcp_tool = tool.to_mcp_tool
result = mcp_tool.call(server_context: nil, name: 'Bob')
#=> Returns MCP::Tool::Response object
```

## Detailed Usage

### Basic Tool Definition

```ruby
tool = ToolForge.define(:file_reader) do
  description 'Reads and processes files'

  # Define parameters with types and validation
  param :filename, type: :string, description: 'Path to file'
  param :encoding, type: :string, required: false, default: 'utf-8'
  param :max_lines, type: :integer, required: false

  # Define execution logic
  execute do |filename:, encoding:, max_lines:|
    content = File.read(filename, encoding: encoding)
    lines = content.lines

    if max_lines
      lines.first(max_lines).join
    else
      content
    end
  end
end
```

### Helper Methods

ToolForge supports two types of helper methods:

#### Instance Helper Methods

Use `helper` for methods that operate on instance data:

```ruby
tool = ToolForge.define(:text_processor) do
  description 'Processes text with formatting'

  param :text, type: :string
  param :format, type: :string, default: 'uppercase'

  # Instance helper method
  helper(:format_text) do |text, format|
    case format
    when 'uppercase' then text.upcase
    when 'lowercase' then text.downcase
    when 'title' then text.split.map(&:capitalize).join(' ')
    else text
    end
  end

  helper(:add_prefix) do |text|
    "PROCESSED: #{text}"
  end

  execute do |text:, format:|
    formatted = format_text(text, format)
    add_prefix(formatted)
  end
end
```

#### Class Helper Methods

Use `class_helper` for utility methods that don't depend on instance state:

```ruby
tool = ToolForge.define(:docker_copy) do
  description 'Copies files to Docker containers'

  param :container_id, type: :string
  param :source_path, type: :string
  param :dest_path, type: :string

  # Class helper method - useful for utilities
  class_helper(:add_to_tar) do |file_path, tar_path|
    # Implementation for tar operations
    "Added #{file_path} to tar archive as #{tar_path}"
  end

  class_helper(:validate_container) do |container_id|
    # Validation logic
    container_id.match?(/^[a-f0-9]{12}$/)
  end

  execute do |container_id:, source_path:, dest_path:|
    return "Invalid container ID" unless self.class.validate_container(container_id)

    tar_result = self.class.add_to_tar(source_path, dest_path)
    "Copied #{source_path} to #{container_id}:#{dest_path} - #{tar_result}"
  end
end
```

### Parameter Types

ToolForge supports various parameter types:

```ruby
tool = ToolForge.define(:complex_tool) do
  param :name, type: :string              # String parameter
  param :count, type: :integer             # Integer parameter
  param :active, type: :boolean            # Boolean parameter
  param :rate, type: :number               # Numeric parameter
  param :tags, type: :array                # Array parameter
  param :metadata, type: :object           # Object/Hash parameter
  param :config, type: :string, required: false, default: 'default.json'

  execute do |**params|
    # Access all parameters
    params.inspect
  end
end
```

### Framework Integration

#### RubyLLM Integration

```ruby
require 'ruby_llm'
require 'tool_forge'

tool = ToolForge.define(:my_tool) do
  # ... tool definition
end

# Convert to RubyLLM format
ruby_llm_class = tool.to_ruby_llm_tool

# Use with RubyLLM
llm = RubyLLM::Client.new
llm.add_tool(ruby_llm_class)
```

#### MCP Integration

```ruby
require 'mcp'
require 'tool_forge'

tool = ToolForge.define(:my_tool) do
  # ... tool definition
end

# Convert to MCP format
mcp_class = tool.to_mcp_tool

# Use with MCP server
server = MCP::Server.new
server.add_tool(mcp_class)
```

## Advanced Features

### Complex Data Processing

```ruby
tool = ToolForge.define(:data_analyzer) do
  description 'Analyzes data files and generates reports'

  param :files, type: :array, description: 'List of file paths'
  param :output_format, type: :string, default: 'json'

  helper(:read_file_data) do |file_path|
    return { error: "File not found: #{file_path}" } unless File.exist?(file_path)

    {
      path: file_path,
      size: File.size(file_path),
      lines: File.readlines(file_path).count,
      modified: File.mtime(file_path)
    }
  end

  helper(:format_output) do |data, format|
    case format
    when 'json' then JSON.pretty_generate(data)
    when 'yaml' then data.to_yaml
    when 'csv' then data.map { |row| row.values.join(',') }.join("\n")
    else data.inspect
    end
  end

  execute do |files:, output_format:|
    results = files.map { |file| read_file_data(file) }

    summary = {
      total_files: results.count,
      total_size: results.sum { |r| r[:size] || 0 },
      files: results
    }

    format_output(summary, output_format)
  end
end
```

### Error Handling

```ruby
tool = ToolForge.define(:safe_processor) do
  description 'Processes data with comprehensive error handling'

  param :input, type: :string
  param :operation, type: :string

  helper(:validate_input) do |input|
    raise ArgumentError, "Input cannot be empty" if input.nil? || input.empty?
    raise ArgumentError, "Input too long" if input.length > 1000
    true
  end

  execute do |input:, operation:|
    begin
      validate_input(input)

      case operation
      when 'reverse' then input.reverse
      when 'upcase' then input.upcase
      when 'analyze' then { length: input.length, words: input.split.count }
      else
        { error: "Unknown operation: #{operation}" }
      end
    rescue => e
      { error: e.message }
    end
  end
end
```

## API Reference

### ToolForge.define(name, &block)

Creates a new tool definition.

- `name` (Symbol): The tool name
- `block`: Configuration block using the DSL

### DSL Methods

#### `description(text)`
Sets the tool description.

#### `param(name, options = {})`
Defines a parameter with options:
- `type`: Parameter type (`:string`, `:integer`, `:boolean`, `:number`, `:array`, `:object`)
- `description`: Parameter description
- `required`: Whether required (default: `true`)
- `default`: Default value for optional parameters

#### `helper(name, &block)`
Defines an instance helper method.

#### `class_helper(name, &block)`
Defines a class helper method.

#### `execute(&block)`
Defines the tool execution logic.

### Conversion Methods

#### `#to_ruby_llm_tool`
Converts to a RubyLLM::Tool class.

#### `#to_mcp_tool`
Converts to an MCP::Tool class.

## Examples

See the [examples directory](examples/) for more comprehensive examples including:
- File processing tools
- API integration tools
- Data transformation tools
- Docker management tools

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/afstanton/tool_forge.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
