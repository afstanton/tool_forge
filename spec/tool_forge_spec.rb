# frozen_string_literal: true

require 'ruby_llm'
require 'mcp'

RSpec.describe ToolForge do
  it 'has a version number' do
    expect(ToolForge::VERSION).not_to be_nil
  end

  describe '.define' do
    it 'creates a new ToolDefinition' do
      tool = described_class.define(:my_tool) do
        description 'A test tool'
      end

      expect(tool).to be_a(ToolForge::ToolDefinition)
      expect(tool.name).to eq(:my_tool)
      expect(tool.description).to eq('A test tool')
    end

    it 'returns a ToolDefinition that can be converted to RubyLLM' do
      tool = described_class.define(:greeting_tool) do
        description 'Greets a user'
        param :name, type: :string
        execute { |name:| "Hello, #{name}!" }
      end

      ruby_llm_class = tool.to_ruby_llm_tool
      expect(ruby_llm_class).to be_a(Class)
      expect(ruby_llm_class.ancestors).to include(RubyLLM::Tool)
    end

    it 'returns a ToolDefinition that can be converted to MCP' do
      tool = described_class.define(:greeting_tool) do
        description 'Greets a user'
        param :name, type: :string
        execute { |name:| "Hello, #{name}!" }
      end

      mcp_class = tool.to_mcp_tool
      expect(mcp_class).to be_a(Class)
      expect(mcp_class.ancestors).to include(MCP::Tool)
    end
  end
end
