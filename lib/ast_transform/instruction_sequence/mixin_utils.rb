# frozen_string_literal: true

module ASTTransform
  module MixinUtils
    class << self
      def try_super(target, method_sym, *args, &block)
        super_method = target.method(method_sym).super_method
        super_method ? super_method.call(*args, &block) : nil
      end
    end
  end
end
