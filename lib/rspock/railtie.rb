# frozen_string_literal: true

module RSpock
  class Railtie < Rails::Railtie
    railtie_name :rspock

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
