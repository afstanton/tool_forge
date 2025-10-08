# frozen_string_literal: true

require 'ruby_llm'

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe ToolForge::ToolDefinition, '#to_ruby_llm_tool' do
  # rubocop:enable RSpec/SpecFilePathFormat
  it 'raises an error if RubyLLM::Tool is not loaded' do
    tool = described_class.new(:my_tool) do
      description 'A test tool'
    end

    # Stub to simulate RubyLLM not being loaded
    stub_const('RubyLLM::Tool', nil)

    expect { tool.to_ruby_llm_tool }.to raise_error(LoadError, /RubyLLM is not loaded/)
  end

  it 'returns a class that inherits from RubyLLM::Tool' do
    tool = described_class.new(:my_tool) do
      description 'A test tool'
    end

    tool_class = tool.to_ruby_llm_tool
    expect(tool_class).to be_a(Class)
    expect(tool_class.ancestors).to include(RubyLLM::Tool)
  end

  it 'sets the tool description' do
    tool = described_class.new(:greeting_tool) do
      description 'Greets a user'
    end

    tool_class = tool.to_ruby_llm_tool
    instance = tool_class.new

    expect(instance.class.description).to eq('Greets a user')
  end

  it 'creates an execute method that calls the block' do
    tool = described_class.new(:greeting_tool) do
      description 'Greets a user'
      param :name, type: :string
      execute { |name:| "Hello, #{name}!" }
    end

    tool_class = tool.to_ruby_llm_tool
    instance = tool_class.new

    result = instance.execute(name: 'Alice')
    expect(result).to eq('Hello, Alice!')
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

    tool_class = tool.to_ruby_llm_tool
    instance = tool_class.new

    expect(instance.execute(name: 'Bob')).to eq('Hello, Bob!')
    expect(instance.execute(name: 'Bob', greeting: 'Hi')).to eq('Hi, Bob!')
  end

  it 'handles tools with multiple parameter types' do
    tool = described_class.new(:complex_tool) do
      description 'A complex tool'
      param :name, type: :string
      param :count, type: :integer
      param :active, type: :boolean
      param :tags, type: :array
      param :metadata, type: :object

      execute do |name:, count:, active:, tags:, metadata:|
        { name: name, count: count, active: active, tags: tags, metadata: metadata }
      end
    end

    tool_class = tool.to_ruby_llm_tool
    instance = tool_class.new

    result = instance.execute(
      name: 'test',
      count: 5,
      active: true,
      tags: %w[a b],
      metadata: { key: 'value' }
    )

    expect(result).to eq(
      name: 'test',
      count: 5,
      active: true,
      tags: %w[a b],
      metadata: { key: 'value' }
    )
  end

  describe 'helper methods' do
    it 'makes helper methods available as instance methods' do
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

      tool_class = tool.to_ruby_llm_tool
      instance = tool_class.new

      # Test that helper methods are available as instance methods
      expect(instance.respond_to?(:add_prefix)).to be true
      expect(instance.respond_to?(:add_suffix)).to be true

      # Test that they work correctly
      expect(instance.add_prefix('Hello')).to eq('PREFIX: Hello')
      expect(instance.add_suffix('World')).to eq('World :SUFFIX')

      # Test the full execution
      result = instance.execute(text: 'Hello')
      expect(result).to eq('PREFIX: Hello :SUFFIX')
    end

    it 'helper methods can access other helper methods' do
      tool = described_class.new(:complex_helper_tool) do
        description 'A tool with interdependent helper methods'
        param :data, type: :string

        helper(:format_data) { |str| "FORMATTED: #{str}" }
        helper(:process_data) { |str| format_data("PROCESSED: #{str}") }

        execute do |data:|
          process_data(data)
        end
      end

      tool_class = tool.to_ruby_llm_tool
      instance = tool_class.new

      result = instance.execute(data: 'test')
      expect(result).to eq('FORMATTED: PROCESSED: test')
    end

    it 'makes class helper methods available as class methods' do
      tool = described_class.new(:docker_tool) do
        description 'A tool with class helper methods'
        param :file_path, type: :string
        param :container_id, type: :string

        class_helper(:add_to_tar) do |file_path, tar_path|
          "Added #{file_path} to tar as #{tar_path}"
        end

        execute do |file_path:, container_id:|
          # Call the class method
          tar_result = self.class.add_to_tar(file_path, "/app/#{File.basename(file_path)}")
          "Copied to container #{container_id}: #{tar_result}"
        end
      end

      tool_class = tool.to_ruby_llm_tool
      instance = tool_class.new

      result = instance.execute(file_path: '/local/file.txt', container_id: 'abc123')
      expect(result).to eq('Copied to container abc123: Added /local/file.txt to tar as /app/file.txt')
    end

    it 'supports both class and instance helper methods together' do
      tool = described_class.new(:complex_tool) do
        description 'A tool with both types of helper methods'
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

      tool_class = tool.to_ruby_llm_tool
      instance = tool_class.new

      result = instance.execute(data: 'test')
      expect(result).to eq('FORMATTED: test + STATIC: test')
    end

    it 'works with tools that have no helper methods' do
      tool = described_class.new(:simple_tool) do
        description 'A simple tool without helpers'
        param :name, type: :string

        execute { |name:| "Hello, #{name}!" }
      end

      tool_class = tool.to_ruby_llm_tool
      instance = tool_class.new

      result = instance.execute(name: 'World')
      expect(result).to eq('Hello, World!')
    end
  end
end
