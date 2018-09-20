# frozen_string_literal: true

module RSpock
  module Helpers
    module StringHelper
      def strip_end_line(str)
        str.gsub(/\n$/, '')
      end
    end
  end
end
