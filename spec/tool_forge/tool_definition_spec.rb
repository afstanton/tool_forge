# frozen_string_literal: true

RSpec.describe ToolForge::ToolDefinition do
  describe '#initialize' do
    it 'can be created with a name' do
      tool = described_class.new(:my_tool)
      expect(tool.name).to eq(:my_tool)
    end

    it 'accepts a block for configuration' do
      tool = described_class.new(:my_tool) do
        description 'Does something cool'
      end
      expect(tool.description).to eq('Does something cool')
    end
  end

  describe '#description' do
    it 'sets and returns the description' do
      tool = described_class.new(:my_tool)
      tool.description 'A helpful tool'
      expect(tool.description).to eq('A helpful tool')
    end
  end

  describe '#param' do
    it 'adds a parameter with basic attributes' do
      tool = described_class.new(:my_tool) do
        param :name, type: :string, description: 'The name'
      end

      expect(tool.params.size).to eq(1)
      expect(tool.params.first[:name]).to eq(:name)
      expect(tool.params.first[:type]).to eq(:string)
      expect(tool.params.first[:description]).to eq('The name')
    end

    it 'accepts required flag' do
      tool = described_class.new(:my_tool) do
        param :id, required: true
        param :optional_field, required: false
      end

      expect(tool.params[0][:required]).to be true
      expect(tool.params[1][:required]).to be false
    end

    it 'defaults required to true' do
      tool = described_class.new(:my_tool) do
        param :id
      end

      expect(tool.params.first[:required]).to be true
    end

    it 'accepts default values' do
      tool = described_class.new(:my_tool) do
        param :count, type: :integer, default: 10
      end

      expect(tool.params.first[:default]).to eq(10)
    end

    it 'supports multiple parameter types' do
      tool = described_class.new(:my_tool) do
        param :name, type: :string
        param :count, type: :integer
        param :active, type: :boolean
        param :tags, type: :array
        param :metadata, type: :object
      end

      types = tool.params.map { |p| p[:type] }
      expect(types).to eq(%i[string integer boolean array object])
    end
  end

  describe '#execute' do
    it 'stores the execution block' do
      tool = described_class.new(:my_tool) do
        execute { |name:| "Hello, #{name}!" }
      end

      expect(tool.execute_block).to be_a(Proc)
    end

    it 'can call the execution block' do
      tool = described_class.new(:my_tool) do
        execute { |name:| "Hello, #{name}!" }
      end

      result = tool.execute_block.call(name: 'World')
      expect(result).to eq('Hello, World!')
    end
  end

  describe 'complete tool definition' do
    it 'can define a complete tool with all features' do
      tool = described_class.new(:greet_user) do
        description 'Greets a user by name'

        param :name, type: :string, description: 'User name', required: true
        param :greeting, type: :string, description: 'Greeting type', required: false, default: 'Hello'
        param :enthusiastic, type: :boolean, description: 'Add excitement', default: false

        execute do |name:, greeting: 'Hello', enthusiastic: false|
          result = "#{greeting}, #{name}"
          result += '!' if enthusiastic
          result
        end
      end

      expect(tool.name).to eq(:greet_user)
      expect(tool.description).to eq('Greets a user by name')
      expect(tool.params.size).to eq(3)
      expect(tool.execute_block.call(name: 'Alice', enthusiastic: true)).to eq('Hello, Alice!')
    end
  end
end
