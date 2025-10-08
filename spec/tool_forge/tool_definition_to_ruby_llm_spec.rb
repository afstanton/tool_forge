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
end
