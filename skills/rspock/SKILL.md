---
name: rspock
description: >-
  MUST be used when writing or modifying Minitest tests in any repo using
  rspock (look for transform!(RSpock::AST::Transformation) in test files or
  rspock in the Gemfile). RSpock rewrites test semantics via AST
  transformation — code that looks like a no-op statement is an assertion,
  and Minitest habits produce silently wrong tests.
---

# RSpock: writing tests

RSpock is a Spock-inspired testing framework on top of Minitest. Tests are
valid Ruby syntax with **different semantics**, applied by AST
transformation at load time. Do not reason about these files as plain
Minitest.

## The invariant that must never be violated

**Inside a `transform!(RSpock::AST::Transformation)` class, every bare
statement in a `Then`/`Expect` block IS an assertion. Outside one, it is
NOT — it evaluates and silently discards.**

Consequences:

- Never write `assert_equal a, b` in an RSpock test — write `a == b` in a
  Then/Expect block. The transform compiles it to an assertion with a
  proper failure message.
- Never write bare comparisons in a plain Minitest class expecting them to
  assert. A file missing the `transform!` annotation is a silently green
  test suite.
- When editing a test file, first check for the `transform!` line at the
  class definition; it decides which dialect you are writing.

## Boilerplate

```ruby
require "test_helper"

transform!(RSpock::AST::Transformation)
class MyThingTest < Minitest::Test
  test "descriptive name" do
    # code blocks here
  end
end
```

The application must install the hook once (usually in the test helper):
`require "ast_transform"; ASTTransform.install`. Mixed files can use
`transform!(RSpock::AST::Transformation.new(strict: false))` to allow
plain Minitest tests alongside.

The transform is an abstraction — trust it. If you ever need to see the
compiled Ruby (debugging only, never as routine verification), the
transformed files are written under `tmp/ast_transform/<relative path>`.

## Code blocks and their order

`Given` (setup) → `When` (stimulus) → `Then` (response), or `Expect`
(stimulus+response in one), plus `Cleanup` (always runs; code defensively
with `&.`) and `Where` (data table, last in source but evaluated first).
Every block takes an optional description string. A `When` is always
followed by a `Then`. Use When+Then for side-effecting code, Expect for
pure functions.

## Assertion forms (Then/Expect)

```ruby
Then "the walk produced the right state"
actual == expected            # binary operators: == != =~ !~ > < >= <=
list.include?(x)              # bare boolean expression asserts
!cart.empty?                  # negation asserts
name = actual.first           # assignments pass through (not assertions)
```

LHS is actual, RHS is expected. Exception assertions live in Then, apply
to the preceding When, one per block:

```ruby
Then "a parse error names the token"
e = raises JSON::ParserError   # capture optional
e.message.include?("unexpected token")
```

`raises` is not supported in Expect blocks.

## Where tables (data-driven)

```ruby
test "adding #{a} and #{b} gives #{c}" do
  Expect
  a + b == c

  Where
  a  | b  | c
  -1 | 1  | 0
  0  | 0  | 0
  1  | 2  | 3
end
```

Header names become local variables and interpolate into the test name.
The table is evaluated in class scope — it cannot see instance methods or
test-local variables. Order rows like a truth table; rightmost column is
the expected result. `_test_index_` / `_line_number_` are available for
pinpointing failing rows.

## Interaction mocking (Then only)

```ruby
Then
1 * subscriber.receive("hello")                 # exactly one call
0 * mailer.deliver                              # must never be called
(1..3) * poller.tick                            # range cardinality
_ * cache.fetch("key") >> cached                # any count, stubbed return
1 * repo.find(42) >> raises(RecordNotFound)     # stubbed exception
1 * ui.frame("Build", &my_block)                # block-identity check
```

Declared in Then but installed before When runs — declare naturally,
RSpock handles ordering. Compiles to Mocha. Inline blocks (`{ }` /
`do...end`) are not allowed in interactions — use a named proc with `&`.
Mocks never yield blocks by design: needing that signals the unit under
test is doing too much — restructure so the mock boundary sits between
responsibilities.

## Pitfalls (wrong → right)

```ruby
# WRONG: Minitest API inside an RSpock class
assert_equal 3, add(1, 2)
# RIGHT
Expect
add(1, 2) == 3
```

```ruby
# WRONG: bare comparison in a class without transform! — silently green
class FooTest < Minitest::Test
  test("x") { compute == 42 }
end
# RIGHT: add transform!(RSpock::AST::Transformation) above the class,
# or use assert_equal in plain Minitest
```

```ruby
# WRONG: Where table using an instance method for column data
Where
input        | expected
helper_val   | 1        # NameError: class scope
# RIGHT: use class methods or literals in Where rows
```

```ruby
# WRONG: expecting a mocked method to yield
1 * ui.with_spinner("work") { drain(io) }
# RIGHT: restructure — mock boundary between responsibilities
success = drain(io)   # test with a real StringIO
1 * ui.ok("work")     # simple expectation, no block
```
