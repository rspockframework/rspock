# frozen_string_literal: true
Rails.backtrace_cleaner.add_filter { |line| RSpock::Backtrace.new.filter_location_string(line) }
Rails.backtrace_cleaner.add_silencer { |line| line =~ /#{Pathname.new('').join('lib', 'ast_transform')}/ }
Rails.backtrace_cleaner.add_silencer { |line| line =~ /#{Pathname.new('').join('lib', 'rspock')}/ }
