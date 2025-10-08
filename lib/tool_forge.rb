# frozen_string_literal: true

require 'json'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup # ready!

require_relative 'tool_forge/version'

# ToolForge provides a unified DSL for defining tools that can be converted
# to both RubyLLM and Model Context Protocol (MCP) formats.
#
# @example Basic usage
#   tool = ToolForge.define(:greet_user) do
#     description 'Greets a user by name'
#     param :name, type: :string, description: 'User name'
#     execute { |name:| "Hello, #{name}!" }
#   end
#
#   # Convert to RubyLLM format
#   ruby_llm_tool = tool.to_ruby_llm_tool
#
#   # Convert to MCP format
#   mcp_tool = tool.to_mcp_tool
module ToolForge
  # Base error class for ToolForge-specific errors
  class Error < StandardError; end

  # Creates a new tool definition with the given name and configuration block.
  #
  # @param name [Symbol] the name of the tool
  # @yield [] block for configuring the tool using the DSL
  # @return [ToolDefinition] a new tool definition instance
  #
  # @example Define a simple tool
  #   tool = ToolForge.define(:calculator) do
  #     description 'Performs basic arithmetic'
  #     param :operation, type: :string, description: 'Operation to perform'
  #     param :a, type: :number, description: 'First number'
  #     param :b, type: :number, description: 'Second number'
  #
  #     execute do |operation:, a:, b:|
  #       case operation
  #       when 'add' then a + b
  #       when 'subtract' then a - b
  #       when 'multiply' then a * b
  #       when 'divide' then b != 0 ? a / b : 'Cannot divide by zero'
  #       else 'Unknown operation'
  #       end
  #     end
  #   end
  def self.define(name, &)
    ToolDefinition.new(name, &)
  end
end
