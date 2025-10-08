# frozen_string_literal: true

module ToolForge
  class ToolDefinition
    attr_reader :name, :params, :execute_block

    def initialize(name, &)
      @name = name
      @description = nil
      @params = []
      @execute_block = nil

      instance_eval(&) if block_given?
    end

    def description(text = nil)
      if text
        @description = text
      else
        @description
      end
    end

    def param(name, type: :string, description: nil, required: true, default: nil)
      @params << {
        name: name,
        type: type,
        description: description,
        required: required,
        default: default
      }
    end

    def execute(&block)
      @execute_block = block
    end

    def to_ruby_llm_tool
      raise LoadError, 'RubyLLM is not loaded. Please require "ruby_llm" first.' unless defined?(RubyLLM::Tool)
      raise LoadError, 'RubyLLM is not loaded. Please require "ruby_llm" first.' if RubyLLM::Tool.nil?

      definition = self

      Class.new(RubyLLM::Tool) do
        description definition.description

        definition.params.each do |param_def|
          param param_def[:name], type: param_def[:type], desc: param_def[:description]
        end

        define_method(:execute) do |**args|
          definition.execute_block.call(**args)
        end
      end
    end

    def to_mcp_tool
      raise LoadError, 'MCP SDK is not loaded. Please require "mcp" first.' unless defined?(MCP::Tool)
      raise LoadError, 'MCP SDK is not loaded. Please require "mcp" first.' if MCP::Tool.nil?

      definition = self

      Class.new(MCP::Tool) do
        description definition.description

        # Build properties hash for input schema
        properties = {}
        required_params = []

        definition.params.each do |param_def|
          prop = {
            type: param_def[:type].to_s
          }
          prop[:description] = param_def[:description] if param_def[:description]

          properties[param_def[:name].to_s] = prop
          required_params << param_def[:name].to_s if param_def[:required]
        end

        input_schema(
          properties: properties,
          required: required_params
        )

        define_singleton_method(:call) do |server_context:, **args|
          result = definition.execute_block.call(**args)
          MCP::Tool::Response.new([{ type: 'text', text: result.to_s }])
        end
      end
    end
  end
end
