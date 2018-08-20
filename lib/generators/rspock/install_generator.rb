# frozen_string_literal: true

# 's' in Rspock is lowercase on purpose, so generator name is +rspock+ instead of +r_spock+
module Rspock
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates RSpock initializer for your application"

      def copy_initializer
        template "rspock_initializer.rb", "config/initializers/rspock.rb"

        puts "Install complete!"
      end
    end
  end
end
