# frozen_string_literal: true

require 'rspock/tasks/truth_table'

namespace :rspock do
  desc 'Generate a Truth Table'
  task :truth_table do
    options = ARGV.select { |arg| arg =~ /.+=.+/ }

    values_mapping = options.map { |arg| arg.split('=') }.to_h
      .transform_values { |value| value.split(/(?<!\\),/).map { |v| v.gsub('\\,', ',') } }
    header = values_mapping.keys

    # truth_table = RSpock::Tasks::TruthTable.generate(header, values_mapping)
    # output = RSpock::Tasks::TruthTable.format(truth_table.unshift(header))
    truth_table = RSpock::Tasks::TruthTable.new(header, values_mapping)
    output = truth_table.to_s
    print output
  end
end
