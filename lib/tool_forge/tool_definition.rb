# frozen_string_literal: true

module ToolForge
  # ToolDefinition is the core class for defining tools that can be converted
  # to both RubyLLM and MCP tool formats. It provides a clean DSL for defining
  # tool metadata, parameters, helper methods, and execution logic.
  #
  # @example Basic tool definition
  #   tool = ToolForge::ToolDefinition.new(:greet_user) do
  #     description 'Greets a user by name'
  #     param :name, type: :string, description: 'User name'
  #     execute { |name:| "Hello, #{name}!" }
  #   end
  #
  # @example Tool with helper methods
  #   tool = ToolForge::ToolDefinition.new(:file_processor) do
  #     description 'Processes files with helper methods'
  #     param :file_path, type: :string
  #
  #     # Instance helper method
  #     helper(:format_data) { |data| "FORMATTED: #{data}" }
  #
  #     # Class helper method (useful for utilities like tar operations)
  #     class_helper(:add_to_tar) { |file, path| "Added #{file} to #{path}" }
  #
  #     execute do |file_path:|
  #       data = File.read(file_path)
  #       formatted = format_data(data)
  #       tar_result = self.class.add_to_tar(file_path, '/archive')
  #       "#{formatted} - #{tar_result}"
  #     end
  #   end
  class ToolDefinition
    # @return [Symbol] the name of the tool
    # @return [Array<Hash>] the parameters defined for the tool
    # @return [Proc] the execution block for the tool
    # @return [Hash] the helper methods organized by type (:instance and :class)
    attr_reader :name, :params, :execute_block, :helper_methods

    # Creates a new tool definition with the given name.
    #
    # @param name [Symbol] the name of the tool
    # @yield [] optional block for configuring the tool using the DSL
    #
    # @example
    #   tool = ToolDefinition.new(:my_tool) do
    #     description 'A sample tool'
    #     param :input, type: :string
    #     execute { |input:| "Processed: #{input}" }
    #   end
    def initialize(name, &)
      @name = name
      @description = nil
      @params = []
      @execute_block = nil
      @helper_methods = { instance: {}, class: {} }

      instance_eval(&) if block_given?
    end

    # Sets or returns the tool description.
    #
    # @param text [String, nil] the description text to set, or nil to return current description
    # @return [String, nil] the current description when called without arguments
    #
    # @example Setting description
    #   description 'This tool processes files'
    #
    # @example Getting description
    #   tool.description #=> 'This tool processes files'
    def description(text = nil)
      if text
        @description = text
      else
        @description
      end
    end

    # Defines a parameter for the tool.
    #
    # @param name [Symbol] the parameter name
    # @param type [Symbol] the parameter type (:string, :integer, :boolean, etc.)
    # @param description [String, nil] optional description of the parameter
    # @param required [Boolean] whether the parameter is required (default: true)
    # @param default [Object, nil] default value for optional parameters
    #
    # @example Required string parameter
    #   param :filename, type: :string, description: 'File to process'
    #
    # @example Optional parameter with default
    #   param :format, type: :string, description: 'Output format', required: false, default: 'json'
    def param(name, type: :string, description: nil, required: true, default: nil)
      @params << {
        name: name,
        type: type,
        description: description,
        required: required,
        default: default
      }
    end

    # Defines the execution logic for the tool.
    #
    # @yield [**args] block that receives tool parameters as keyword arguments
    # @return [void]
    #
    # @example
    #   execute do |filename:, format:|
    #     data = File.read(filename)
    #     format == 'json' ? JSON.parse(data) : data
    #   end
    def execute(&block)
      @execute_block = block
    end

    # Defines an instance helper method that can be called within the execute block.
    # Instance helper methods are available as regular method calls in the execution context.
    #
    # @param method_name [Symbol] the name of the helper method
    # @yield [*args] block that defines the helper method logic
    # @return [void]
    #
    # @example
    #   helper(:format_output) do |data|
    #     "FORMATTED: #{data.upcase}"
    #   end
    #
    #   execute do |input:|
    #     format_output(input) # Called as instance method
    #   end
    def helper(method_name, &block)
      @helper_methods[:instance][method_name] = block
    end

    # Defines a class helper method that can be called within the execute block.
    # Class helper methods are useful for utility functions that don't depend on instance state.
    # They are accessed via self.class.method_name in the execution context.
    #
    # @param method_name [Symbol] the name of the class helper method
    # @yield [*args] block that defines the helper method logic
    # @return [void]
    #
    # @example
    #   class_helper(:add_to_tar) do |file_path, tar_path|
    #     # Implementation for adding files to tar archive
    #     "Added #{file_path} to tar as #{tar_path}"
    #   end
    #
    #   execute do |file:|
    #     self.class.add_to_tar(file, '/archive/file.tar') # Called as class method
    #   end
    def class_helper(method_name, &block)
      @helper_methods[:class][method_name] = block
    end

    # Converts this tool definition to a RubyLLM::Tool class.
    # The resulting class can be instantiated and used with the RubyLLM framework.
    #
    # Instance helper methods become instance methods on the generated class.
    # Class helper methods become singleton methods on the generated class.
    #
    # @return [Class] a class that inherits from RubyLLM::Tool
    # @raise [LoadError] if RubyLLM is not loaded
    #
    # @example
    #   tool_class = tool_definition.to_ruby_llm_tool
    #   instance = tool_class.new
    #   result = instance.execute(filename: 'data.txt')
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

    # Converts this tool definition to an MCP::Tool class.
    # The resulting class can be used with the Model Context Protocol framework.
    #
    # Both instance and class helper methods are available in the execution context.
    # Class helper methods are accessed via self.class.method_name.
    #
    # @return [Class] a class that inherits from MCP::Tool
    # @raise [LoadError] if MCP SDK is not loaded
    #
    # @example
    #   tool_class = tool_definition.to_mcp_tool
    #   result = tool_class.call(server_context: nil, filename: 'data.txt')
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
