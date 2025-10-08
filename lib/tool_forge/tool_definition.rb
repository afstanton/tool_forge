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
  end
end
