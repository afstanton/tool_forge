# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.setup # ready!

require_relative 'tool_forge/version'

module ToolForge
  class Error < StandardError; end
  # Your code goes here...
end
