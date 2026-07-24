# frozen_string_literal: true

require 'rspock/version'

require 'rspock/declarative'

require 'ast_transform'
ASTTransform.acronym('RSpock')

require 'rspock/ast/transformation'
require 'rspock/helpers/block_capture'

require 'rspock/railtie' if defined?(Rails)
