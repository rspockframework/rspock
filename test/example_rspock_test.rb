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

  # --- Statement assertions ---

  test "regex match with =~ in Expect" do
    Expect
    "hello potato world" =~ /potato/
  end

  test "comparison operators in Then with #{a}" do
    Given
    stack = []

    When
    stack.push(a)

    Then
    stack.size == 1
    stack.size > 0
    stack.size >= 1
    stack.size < 2
    stack.size <= 1

    Where
    a
    "potato"
    "tomato"
  end

  test "bare boolean expressions in Expect" do
    Expect
    [1, 2, 3].include?(2)
    "hello".is_a?(String)
    "hello".respond_to?(:length)
  end

  test "negation in Then" do
    Given
    stack = [1]

    When
    stack.push(2)

    Then
    !stack.empty?
    !stack.nil?
  end

  test "variable assignment in Then does not break" do
    Given
    stack = []

    When
    stack.push("item")

    Then
    result = stack.first
    result == "item"
  end

  # --- Raises conditions ---

  test "raises catches expected exception" do
    Given
    stack = []

    When
    stack.fetch(99)

    Then
    raises IndexError
  end

  test "raises with capture allows property assertions" do
    Given
    stack = []

    When
    stack.fetch(99)

    Then
    e = raises IndexError
    e.message =~ /index 99/
  end

  test "raises with Where block for #{error_class}" do
    When
    Integer(input)

    Then
    raises error_class

    Where
    input   | error_class
    "abc"   | ArgumentError
    "hello" | ArgumentError
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
