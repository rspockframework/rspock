# frozen_string_literal: true

module RSpock
  module Helpers
    module BlockCapture
      # Installs a block-capture wrapper on +obj+ for +method_name+.
      # Must be called AFTER Mocha's expects/stubs so the wrapper sits
      # in front of whatever Mocha installed.
      #
      # Returns a lambda that, when called, returns the captured block
      # (or nil if no block was passed).
      def self.capture(obj, method_name)
        state = { captured: nil }

        if obj.respond_to?(method_name, true)
          # Real objects or objects where Mocha defined the method on
          # the singleton class. Prepend a module so we intercept the
          # call before Mocha's stub (prepend wins over define_singleton_method).
          s = state
          capture_mod = Module.new do
            define_method(method_name) do |*args, **kwargs, &blk|
              s[:captured] = blk
              super(*args, **kwargs, &blk)
            end
          end
          obj.singleton_class.prepend(capture_mod)
        else
          # Mock objects where the method goes through method_missing.
          original_mm = obj.method(:method_missing)
          s = state
          obj.define_singleton_method(:method_missing) do |name, *args, **kwargs, &blk|
            s[:captured] = blk if name == method_name
            original_mm.call(name, *args, **kwargs, &blk)
          end
        end

        -> { state[:captured] }
      end
    end
  end
end
