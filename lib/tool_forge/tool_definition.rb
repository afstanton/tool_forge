# frozen_string_literal: true

module ToolForge
  class ToolDefinition
    attr_reader :name, :params, :execute_block, :helper_methods

    def initialize(name, &)
      @name = name
      @description = nil
      @params = []
      @execute_block = nil
      @helper_methods = { instance: {}, class: {} }

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

    def helper(method_name, &block)
      @helper_methods[:instance][method_name] = block
    end

    def class_helper(method_name, &block)
      @helper_methods[:class][method_name] = block
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

        # Add instance helper methods
        definition.helper_methods[:instance].each do |method_name, method_block|
          define_method(method_name, &method_block)
        end

        # Add class helper methods
        definition.helper_methods[:class].each do |method_name, method_block|
          define_singleton_method(method_name, &method_block)
        end

        define_method(:execute) do |**args|
          # Execute the block in the context of this instance so helper methods are available
          instance_exec(**args, &definition.execute_block)
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

        # Create a helper object that contains all the helper methods
        helper_class = Class.new do
          definition.helper_methods[:instance].each do |method_name, method_block|
            define_method(method_name, &method_block)
          end

          # Class methods are defined as singleton methods on the class itself
          definition.helper_methods[:class].each do |method_name, method_block|
            define_singleton_method(method_name, &method_block)
          end
        end

        define_singleton_method(:call) do |server_context:, **args|
          # Create an instance of the helper class to provide context for helper methods
          helper_instance = helper_class.new

          # Execute the block in the context of the helper instance so helper methods are available
          # For class methods, they'll be available on the helper_class itself
          result = helper_instance.instance_exec(**args, &definition.execute_block)

          # Smart formatting for different return types
          result_text = case result
                        when String
                          result
                        when Hash, Array
                          JSON.pretty_generate(result)
                        else
                          result.to_s
                        end

          MCP::Tool::Response.new([{ type: 'text', text: result_text }])
        end
      end
    end
  end
end
