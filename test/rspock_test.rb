require "test_helper"

class RSpockTest < Minitest::Test
  extend RSpock::Declarative

  test "that it has a version number" do
    refute_nil ::RSpock::VERSION
  end
end
