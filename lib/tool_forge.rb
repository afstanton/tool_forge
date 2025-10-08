# frozen_string_literal: true

require 'json'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup # ready!

require_relative 'tool_forge/version'

module ToolForge
  class Error < StandardError; end

  def self.define(name, &)
    ToolDefinition.new(name, &)
  end
end
