# frozen_string_literal: true

# Example: Docker Copy Tool
# Demonstrates class helper methods for utility functions

require 'tool_forge'

docker_copy_tool = ToolForge.define(:docker_copy) do
  description 'Copies files to Docker containers with tar archive support'

  param :container_id, type: :string, description: 'Docker container ID'
  param :source_path, type: :string, description: 'Local file path to copy'
  param :dest_path, type: :string, description: 'Destination path in container'
  param :create_archive, type: :boolean, required: false, default: true

  # Class helper method for tar operations
  class_helper(:add_to_tar) do |file_path, tar_path|
    # In a real implementation, this would create a tar archive
    {
      operation: 'tar_add',
      source: file_path,
      target: tar_path,
      timestamp: Time.now.iso8601,
      success: true
    }
  end

  # Class helper method for container validation
  class_helper(:validate_container_id) do |container_id|
    # Simple validation - real implementation would check with Docker
    container_id.match?(/^[a-f0-9]{12,64}$/)
  end

  # Instance helper method for formatting results
  helper(:format_result) do |operation_result, container_id, dest_path|
    if operation_result[:success]
      "✅ Successfully copied to #{container_id}:#{dest_path} at #{operation_result[:timestamp]}"
    else
      "❌ Failed to copy: #{operation_result[:error]}"
    end
  end

  execute do |container_id:, source_path:, dest_path:, create_archive:|
    # Validate container ID using class helper
    unless self.class.validate_container_id(container_id)
      return { error: "Invalid container ID format: #{container_id}" }
    end

    # Check if source file exists
    return { error: "Source file not found: #{source_path}" } unless File.exist?(source_path)

    begin
      if create_archive
        # Use class helper for tar operations
        tar_result = self.class.add_to_tar(source_path, dest_path)

        # Use instance helper for formatting
        format_result(tar_result, container_id, dest_path)
      else
        # Direct copy simulation
        {
          message: "Direct copy to #{container_id}:#{dest_path}",
          source: source_path,
          destination: dest_path,
          method: 'direct_copy',
          timestamp: Time.now.iso8601
        }
      end
    rescue StandardError => e
      { error: "Copy operation failed: #{e.message}" }
    end
  end
end

# Example usage:
if __FILE__ == $PROGRAM_NAME
  # This would normally require the actual RubyLLM or MCP frameworks
  puts 'Docker Copy Tool Definition Created'
  puts "Description: #{docker_copy_tool.description}"
  puts "Parameters: #{docker_copy_tool.params.map { |p| p[:name] }.join(', ')}"
  puts "Helper methods: #{docker_copy_tool.helper_methods.map { |type, methods| "#{type}: #{methods.keys}" }}"
end
