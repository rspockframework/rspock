# frozen_string_literal: true
Rails.backtrace_cleaner.add_filter { |line| RSpock::BacktraceFilter.new.filter_string(line) }
