# frozen_string_literal: true
require 'ast_transform/source_map'

module RSpock
  class BacktraceFilter
    # Constructs a new BacktraceFilter instance.
    #
    # @param source_map_provider [::ASTTransform::SourceMap] The source map provider to be used.
    def initialize(source_map_provider: ::ASTTransform::SourceMap)
      @source_map_provider = source_map_provider
    end

    # Filters the backtrace of the given +exception+ and applies the filtered backtrace to the exception.
    #
    # @param exception [Exception] The exception to be filtered.
    #
    # @return [void]
    def filter_exception(exception)
      exception.set_backtrace(source_mapped_backtrace(exception))
    end

    # Filters the given location.
    #
    # @param location [String] A location string.
    #
    # @return [String] The filtered location.
    def filter_string(location)
      file_path, lineno = location.match(/([\S]+):(\d+)/).captures
      lineno = lineno.to_i
      absolute_path = File.expand_path(file_path)

      source_map = @source_map_provider.for_file_path(absolute_path)
      return location unless source_map

      line_number = source_map.line(lineno) || '?'
      location.gsub(/tmp\/rspock\/([\S]+):(\d+)/, "\\1:#{line_number}")
    end

    private

    def source_mapped_backtrace(e)
      e.backtrace_locations&.map(&method(:location_builder))
    end

    def location_builder(location)
      source_map = @source_map_provider.for_file_path(location.absolute_path || location.path)
      return location.to_s unless source_map

      line_number = source_map.line(location.lineno) || '?'
      "#{source_map.source_file_path}:#{line_number}"
    end
  end
end
