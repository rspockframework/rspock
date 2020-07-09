# frozen_string_literal: true
require 'test_helper'

transform!(RSpock::AST::Transformation)
class ExampleRSpockTest < Minitest::Test
  class Foo
    def initialize(dep)
      @dep = dep
    end

    def foo
      @dep.foo(1)
      @dep.foo(3)
      @dep.foo(4)
      @dep.foo(6)
    end
  end

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

  test "Without Where Block" do
    Expect
    self.class.mul(2, 2) == 4

    Cleanup
  end

  test "interactions" do
    Given
    dep = mock
    foo = Foo.new(dep)

    When
    foo.foo

    Then
    0 * dep.bar
    1 * dep.foo(1)
    _ * dep.foo(2)
    (1..2) * dep.foo(3)
    (1...4) * dep.foo(4)
    (_..2) * dep.foo(5)
    (1.._) * dep.foo(6)
    (_.._) * dep.foo(7)
  end
end
