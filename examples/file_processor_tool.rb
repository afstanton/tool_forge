# frozen_string_literal: true

# Example: File Processor Tool
# Demonstrates instance helper methods and complex data processing

require 'tool_forge'

file_processor_tool = ToolForge.define(:file_processor) do
  description 'Processes text files with various transformations and analysis'

  param :file_path, type: :string, description: 'Path to the file to process'
  param :operations, type: :array, description: 'List of operations to perform'
  param :output_format, type: :string, required: false, default: 'json'
  param :preserve_original, type: :boolean, required: false, default: true

  # Instance helper methods for text processing
  helper(:read_file_content) do |path|
    return { error: "File not found: #{path}" } unless File.exist?(path)

    {
      content: File.read(path),
      size: File.size(path),
      lines: File.readlines(path).count,
      encoding: File.read(path).encoding.name
    }
  end

  helper(:analyze_text) do |content|
    lines = content.lines
    words = content.split(/\s+/)

    {
      character_count: content.length,
      word_count: words.length,
      line_count: lines.length,
      average_line_length: lines.empty? ? 0 : (content.length.to_f / lines.length).round(2),
      longest_word: words.max_by(&:length) || '',
      unique_words: words.map(&:downcase).uniq.length
    }
  end

  helper(:transform_text) do |content, operation|
    case operation.downcase
    when 'uppercase'
      content.upcase
    when 'lowercase'
      content.downcase
    when 'title_case'
      content.split.map(&:capitalize).join(' ')
    when 'reverse_lines'
      content.lines.reverse.join
    when 'reverse_words'
      content.split.reverse.join(' ')
    when 'remove_blank_lines'
      content.lines.reject { |line| line.strip.empty? }.join
    when 'number_lines'
      content.lines.map.with_index(1) { |line, i| "#{i}. #{line}" }.join
    else
      content
    end
  end

  helper(:format_output) do |data, format|
    case format.downcase
    when 'json'
      JSON.pretty_generate(data)
    when 'yaml'
      begin
        require 'yaml'
        data.to_yaml
      rescue LoadError
        "YAML not available, falling back to JSON:\n#{JSON.pretty_generate(data)}"
      end
    when 'text'
      if data.is_a?(Hash)
        data.map { |k, v| "#{k}: #{v}" }.join("\n")
      else
        data.to_s
      end
    else
      data.inspect
    end
  end

  execute do |file_path:, operations:, output_format:, preserve_original:|
    # Read the file
    file_data = read_file_content(file_path)
    return file_data if file_data[:error]

    content = file_data[:content]
    original_content = preserve_original ? content.dup : nil

    # Process each operation
    processed_content = content
    operation_results = []

    operations.each do |operation|
      case operation.downcase
      when 'analyze'
        analysis = analyze_text(processed_content)
        operation_results << { operation: operation, result: analysis }
      else
        # Text transformation
        old_content = processed_content
        processed_content = transform_text(processed_content, operation)
        operation_results << {
          operation: operation,
          applied: old_content != processed_content,
          preview: processed_content[0..100] + (processed_content.length > 100 ? '...' : '')
        }
      end
    end

    # Prepare final result
    result = {
      file_info: file_data.except(:content),
      operations_applied: operation_results,
      final_content: processed_content,
      processing_summary: {
        operations_count: operations.length,
        content_changed: preserve_original ? (original_content != processed_content) : nil,
        final_size: processed_content.length
      }
    }

    result[:original_content] = original_content if preserve_original

    # Format output according to preference
    format_output(result, output_format)
  rescue StandardError => e
    format_output({ error: e.message, backtrace: e.backtrace.first(3) }, output_format)
  end
end

# Example usage:
if __FILE__ == $PROGRAM_NAME
  puts 'File Processor Tool Definition Created'
  puts "Description: #{file_processor_tool.description}"
  puts "Parameters: #{file_processor_tool.params.map { |p| "#{p[:name]} (#{p[:type]})" }.join(', ')}"

  # Example of what the tool can do:
  puts "\nSupported operations:"
  puts '- analyze: Provides text statistics'
  puts '- uppercase, lowercase, title_case: Text case transformations'
  puts '- reverse_lines, reverse_words: Content reversal'
  puts '- remove_blank_lines: Cleanup operations'
  puts '- number_lines: Add line numbers'
end
