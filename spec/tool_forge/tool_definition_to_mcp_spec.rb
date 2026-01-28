# frozen_string_literal: true

require 'mcp'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe ToolForge::ToolDefinition, '#to_mcp_tool' do
  # rubocop:enable RSpec/SpecFilePathFormat
  it 'raises an error if MCP::Tool is not loaded' do
    tool = described_class.new(:my_tool) do
      description 'A test tool'
    end

    # Stub to simulate MCP not being loaded
    stub_const('MCP::Tool', nil)

    expect { tool.to_mcp_tool }.to raise_error(LoadError, /MCP SDK is not loaded/)
  end

  it 'returns a class that inherits from MCP::Tool' do
    tool = described_class.new(:my_tool) do
      description 'A test tool'
    end

    tool_class = tool.to_mcp_tool
    expect(tool_class).to be_a(Class)
    expect(tool_class.ancestors).to include(MCP::Tool)
  end

  it 'sets the tool description' do
    tool = described_class.new(:greeting_tool) do
      description 'Greets a user'
    end

    tool_class = tool.to_mcp_tool

    # MCP::Tool stores description at class level
    expect(tool_class.description).to eq('Greets a user')
  end

  it 'defines input schema with parameters' do
    tool = described_class.new(:my_tool) do
      description 'A test tool'
      param :name, type: :string, description: 'User name', required: true
      param :age, type: :integer, description: 'User age', required: false
    end

    tool_class = tool.to_mcp_tool
    schema = tool_class.input_schema.to_h

    expect(schema[:properties]).to have_key(:name)
    expect(schema[:properties][:name][:type]).to eq('string')
    expect(schema[:properties][:name][:description]).to eq('User name')

    expect(schema[:properties]).to have_key(:age)
    expect(schema[:properties][:age][:type]).to eq('integer')
    expect(schema[:properties][:age][:description]).to eq('User age')

    expect(schema[:required]).to eq(['name'])
  end

  it 'creates a call method that executes the block' do
    tool = described_class.new(:greeting_tool) do
      description 'Greets a user'
      param :name, type: :string
      execute { |name:| "Hello, #{name}!" }
    end

    tool_class = tool.to_mcp_tool

    result = tool_class.call(server_context: nil, name: 'Alice')
    expect(result).to be_a(MCP::Tool::Response)
    expect(result.content.first[:text]).to eq('Hello, Alice!')
  end

  it 'handles tools with default values' do
    tool = described_class.new(:greeting_tool) do
      description 'Greets a user'
      param :name, type: :string
      param :greeting, type: :string, default: 'Hello'

      execute do |name:, greeting: 'Hello'|
        "#{greeting}, #{name}!"
      end
    end

    tool_class = tool.to_mcp_tool

    result1 = tool_class.call(server_context: nil, name: 'Bob')
    expect(result1.content.first[:text]).to eq('Hello, Bob!')

    result2 = tool_class.call(server_context: nil, name: 'Bob', greeting: 'Hi')
    expect(result2.content.first[:text]).to eq('Hi, Bob!')
  end

  it 'handles tools with multiple parameter types' do
    tool = described_class.new(:complex_tool) do
      description 'A complex tool'
      param :name, type: :string
      param :count, type: :integer
      param :active, type: :boolean

      execute do |name:, count:, active:|
        { name: name, count: count, active: active }.to_s
      end
    end

    tool_class = tool.to_mcp_tool
    schema = tool_class.input_schema.to_h

    expect(schema[:properties][:name][:type]).to eq('string')
    expect(schema[:properties][:count][:type]).to eq('integer')
    expect(schema[:properties][:active][:type]).to eq('boolean')

    result = tool_class.call(server_context: nil, name: 'test', count: 5, active: true)
    expect(result).to be_a(MCP::Tool::Response)
  end

  it 'converts type symbols to JSON schema types' do
    tool = described_class.new(:type_test) do
      description 'Tests type conversion'
      param :str, type: :string
      param :int, type: :integer
      param :bool, type: :boolean
      param :arr, type: :array
      param :obj, type: :object
    end

    tool_class = tool.to_mcp_tool
    schema = tool_class.input_schema.to_h

    expect(schema[:properties][:str][:type]).to eq('string')
    expect(schema[:properties][:int][:type]).to eq('integer')
    expect(schema[:properties][:bool][:type]).to eq('boolean')
    expect(schema[:properties][:arr][:type]).to eq('array')
    expect(schema[:properties][:obj][:type]).to eq('object')
  end

  describe 'return value formatting' do
    it 'returns strings as-is' do
      tool = described_class.new(:string_tool) do
        description 'Returns a string'
        execute { 'Hello, World!' }
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil)
      expect(result.content.first[:text]).to eq('Hello, World!')
    end

    it 'formats hashes as pretty JSON' do
      tool = described_class.new(:hash_tool) do
        description 'Returns a hash'
        execute { { name: 'Alice', age: 30 } }
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil)
      parsed = JSON.parse(result.content.first[:text])
      expect(parsed).to eq('name' => 'Alice', 'age' => 30)
    end

    it 'formats arrays as pretty JSON' do
      tool = described_class.new(:array_tool) do
        description 'Returns an array'
        execute { [1, 2, 3, 4, 5] }
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil)
      parsed = JSON.parse(result.content.first[:text])
      expect(parsed).to eq([1, 2, 3, 4, 5])
    end

    it 'converts other objects to strings' do
      tool = described_class.new(:number_tool) do
        description 'Returns a number'
        execute { 42 }
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil)
      expect(result.content.first[:text]).to eq('42')
    end
  end

  describe 'helper methods' do
    it 'makes helper methods available in the execute block' do
      tool = described_class.new(:helper_tool) do
        description 'A tool with helper methods'
        param :text, type: :string

        helper(:add_prefix) { |str| "PREFIX: #{str}" }
        helper(:add_suffix) { |str| "#{str} :SUFFIX" }

        execute do |text:|
          prefixed = add_prefix(text)
          add_suffix(prefixed)
        end
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil, text: 'Hello')
      expect(result.content.first[:text]).to eq('PREFIX: Hello :SUFFIX')
    end

    it 'helper methods can access parameters and return complex data' do
      tool = described_class.new(:complex_helper_tool) do
        description 'A tool with complex helper methods'
        param :files, type: :array
        param :operation, type: :string

        helper(:process_file) do |filename, op|
          { file: filename, operation: op, processed: true }
        end

        execute do |files:, operation:|
          results = files.map { |file| process_file(file, operation) }
          { processed_files: results, total: results.size }
        end
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil, files: ['file1.txt', 'file2.txt'], operation: 'compress')

      parsed_result = JSON.parse(result.content.first[:text])
      expect(parsed_result['total']).to eq(2)
      expect(parsed_result['processed_files'].first['file']).to eq('file1.txt')
      expect(parsed_result['processed_files'].first['operation']).to eq('compress')
      expect(parsed_result['processed_files'].first['processed']).to be true
    end

    it 'makes class helper methods available in the execute block' do
      tool = described_class.new(:docker_mcp_tool) do
        description 'A tool with class helper methods for MCP'
        param :file_path, type: :string
        param :container_id, type: :string

        class_helper(:add_to_tar) do |file_path, tar_path|
          "Added #{file_path} to tar as #{tar_path}"
        end

        execute do |file_path:, container_id:|
          # Access class method through the helper class
          tar_result = self.class.add_to_tar(file_path, "/app/#{File.basename(file_path)}")
          "Copied to container #{container_id}: #{tar_result}"
        end
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil, file_path: '/local/file.txt', container_id: 'abc123')
      expected_text = 'Copied to container abc123: Added /local/file.txt to tar as /app/file.txt'
      expect(result.content.first[:text]).to eq(expected_text)
    end

    it 'supports both class and instance helper methods together in MCP' do
      tool = described_class.new(:complex_mcp_tool) do
        description 'A tool with both types of helper methods for MCP'
        param :data, type: :string

        helper(:format_data) do |data|
          "FORMATTED: #{data}"
        end

        class_helper(:process_static) do |input|
          "STATIC: #{input}"
        end

        execute do |data:|
          formatted = format_data(data)
          static = self.class.process_static(data)
          "#{formatted} + #{static}"
        end
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil, data: 'test')
      expect(result.content.first[:text]).to eq('FORMATTED: test + STATIC: test')
    end

    it 'works with tools that have no helper methods' do
      tool = described_class.new(:simple_tool) do
        description 'A simple tool without helpers'
        param :name, type: :string

        execute { |name:| "Hello, #{name}!" }
      end

      tool_class = tool.to_mcp_tool
      result = tool_class.call(server_context: nil, name: 'World')
      expect(result.content.first[:text]).to eq('Hello, World!')
    end
  end
end
