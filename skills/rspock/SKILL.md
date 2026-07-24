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

- Inside a `transform!` class, write expression assertions — `a == b` in a
  Then/Expect block. The transform compiles them to assertions with proper
  failure messages; the Minitest assert API is not the dialect here.
- In a plain Minitest class, use the assert API (`assert_equal` and
  friends). A bare comparison there evaluates and discards — a silently
  green test.
- When editing a test file, first check for the `transform!` line at each
  class definition; it decides which dialect that class speaks. Both
  styles may legitimately coexist in one file (see `strict: false` below)
  — match the dialect of the class you are in.

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
`require "ast_transform"; ASTTransform.install`. That is the whole setup —
Rails apps need nothing extra (backtraces and debuggers are source-true by
construction; there is no backtrace cleaner to configure). Mixed files can
use `transform!(RSpock::AST::Transformation.new(strict: false))` to allow
plain Minitest tests alongside — this exists to ease gradual migration,
so treat mixed files as normal, not as something to unify.

The transform is an abstraction — trust it. If you ever need to see the
compiled Ruby (debugging only, never as routine verification), the
transformed files are written under `tmp/ast_transform/<relative path>`;
they are emitted line-aligned, so their line numbers match your source
exactly.

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
the expected result.

To generate an exhaustive table instead of writing it by hand:

```
rake rspock:truth_table -- a=-1,0,1 b=-1,0,1 expected_result="'?'"
```

It emits the formatted cross-product (fill the `'?'` column manually).
Escape commas inside a value with `\,` (e.g. `b="gen(1\, 2)","gen(3\, 4)"`).
Non-Rails projects must load the gem's Rakefile once to get the task —
see the README's installation section.

## Interaction mocking (Then only)

```ruby
Then
1 * subscriber.receive("hello")                 # exactly one call
0 * mailer.deliver                              # must never be called
(1..3) * poller.tick                            # between one and three
(1.._) * poller.tick                            # at least once
(_..3) * poller.tick                            # at most three times
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

## Debugging failures

- Backtraces AND debugger display are source-true: transformed code is
  emitted with every statement on its original source line, so line
  numbers point at the file you wrote with no mapping layer. Trust them;
  don't second-guess against `tmp/ast_transform/`.
- `break file:line` binds on user statements; interactive debuggers show
  your real source. One documented oddity: interaction setups execute
  before the When body, so stepping through a test with interactions
  jumps from the interaction lines back up to the When line once.
- To isolate a Where row: the generated test name embeds the row's index
  and source line (e.g. `... 1 line 15`). For a newly failing row, copy
  the rerun command printed with the failure and add a plain
  `binding.pry`. For a chosen row, run `-n /line_15/` with the line from
  the editor gutter, or break conditionally on the column locals
  themselves (`binding.pry if input == "not json"`). A source-line
  breakpoint on a data row cannot isolate its run — the table evaluates
  once, in class scope; name-selection is the mechanism.

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
