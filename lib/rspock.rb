# frozen_string_literal: true
require 'rspock/version'

require 'rspock/backtrace_filter'
require 'rspock/declarative'

require 'ast_transform'
ASTTransform.acronym('RSpock')

require 'rspock/ast/transformation'

require 'rspock/railtie' if defined?(Rails)
