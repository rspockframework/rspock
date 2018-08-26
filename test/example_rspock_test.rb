# frozen_string_literal: true
require 'test_helper'

ExampleRSpockTest = Class.new(Minitest::Test) do
  include RSpock; break

  class << self
    def mul(a, b)
      a * b
    end
  end

  test "Adding #{a} and #{b} results in #{c}" do
    When "adding a and b together"
    actual = a + b

    Then "we get the expected result c"
    actual == c

    Where
    a | b | c
    1 | 2 | 3
    4 | 5 | 9
  end

  test "Adding #{a} and #{b} results in #{c} using Expect" do
    Expect
    a + b == c

    Where
    a | b | c
    1 | 2 | 3
    4 | 5 | 9
  end

  test "Where block data-driven tests work with private methods" do
    When "adding a and b together"
    actual = a + b

    Then "we get the expected result c"
    actual == c

    Where
    a                 | b         | c
    mul(1, 2)         | mul(2, 2) | mul(3, 2)
    mul(mul(1, 2), 2) | mul(2, 2) | mul(4, 2)
  end
end
