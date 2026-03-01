# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.5.0] - 2026-02-28

### Added

- Exception conditions: `raises ExceptionClass` in Then blocks wraps the preceding When block in an exception assertion.
- Exception capture: `e = raises ExceptionClass` captures the exception for further assertions in the same Then block.
- Exception conditions work with data-driven `Where` blocks.

### Changed

- Renamed interaction outcome nodes from `rspock_returns` / `rspock_raises` to `rspock_stub_returns` / `rspock_stub_raises` to distinguish them from the new exception condition `rspock_raises`.

## [2.4.0] - 2026-02-28

### Added

- Spock-style implicit assertions: every non-assignment statement in Then/Expect blocks is now an assertion — no assertion API needed.
- Binary operator assertions: `=~`, `!~`, `>`, `<`, `>=`, `<=` with clear error messages.
- General statement assertions: bare boolean expressions (e.g. `obj.valid?`) with the original source text in the error message.
- Negation support: `!expr` is detected automatically and produces a clear error message.
- `>> raises(...)` syntax for exception stubbing in interactions.

### Changed

- Renamed `ConditionParser` to `StatementParser` and `ConditionToAssertionTransformation` to `StatementToAssertionTransformation` for consistency with Spock's model.
- Then and Expect block parsers now use `StatementParser` for statement classification.

### Removed

- `ComparisonToAssertionTransformation` — replaced by `StatementToAssertionTransformation`.

## [2.3.1] - 2026-02-27

### Fixed

- Require `block_capture` so it is available at runtime.

## [2.3.0] - 2026-02-27

### Added

- Interaction transformations and block identity verification via `&` operator.
- RSpock AST node hierarchy (`Node`, `InteractionNode`, `BodyNode`, etc.) for type-safe AST handling.
- `TestMethodParser` extracted from `TestMethodTransformation` for separation of parsing and transformation.

### Changed

- Restructured block classes into `Parser` namespace and converted `InteractionParser` to a class.
- Introduced `BodyNode` and removed legacy interaction transformations.

## [2.2.0] - 2026-02-25

### Added

- Interaction stubbing with `>>` for return value stubbing in Then block interactions.

### Fixed

- Pry and pry-byebug compatibility.
- Failing test on Ruby 3+.
- `filter_string` for `ast_transform` 2.1.4 source mapping change.

## [2.1.0] - 2026-02-21

### Added

- Ruby 4.0 support.

### Fixed

- Codecov badge URL to use master branch.

## [2.0.0] - 2026-02-21

### Changed

- Minimum Ruby version bumped to 3.2.
- Upgraded to Ruby 3.x compatibility.
- Use `ast_transform` 2.0.0 from RubyGems.
- CI modernization and release workflow improvements.

## [1.0.0] - 2020-07-09

### Added

- Interaction-based testing: mock with expectations in the Then block.
- Travis CI and code coverage.

### Changed

- Test names now have the test index and line number as suffix instead of prefix.
- Removed unnecessary ensure block when Cleanup block is empty; moved source map wrapper to class scope.
- Bump `ast_transform` to release 1.0.0.

### Fixed

- Source mapping for transformed assertion nodes.
- Truth table generator command with proper escaping.

## [0.2.5] - 2019-05-28

### Fixed

- BacktraceFilter so that source mapping works again.

## [0.2.4] - 2019-05-27

### Changed

- Bump Unparser dependency from `~> 0.2.8` to `~> 0.4`.

## [0.2.3] - 2018-11-09

### Fixed

- Cleanup block can now contain more than one node.

## [0.2.2] - 2018-11-08

### Changed

- Extracted ASTTransform to its own gem: `ast_transform`.

## [0.2.1] - 2018-10-09

### Added

- `_line_number_` is now displayed in the test name and available in test scope for debugging.

### Changed

- Renamed `test_index` to `_test_index_`.

## [0.2.0] - 2018-09-21

### Added

- Truth table generator Rake task.

## [0.1.1] - 2018-09-18

### Added

- Initial release.

[Unreleased]: https://github.com/rspockframework/rspock/compare/v2.5.0...HEAD
[2.5.0]: https://github.com/rspockframework/rspock/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/rspockframework/rspock/compare/v2.3.1...v2.4.0
[2.3.1]: https://github.com/rspockframework/rspock/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/rspockframework/rspock/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/rspockframework/rspock/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/rspockframework/rspock/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/rspockframework/rspock/compare/1.0.0...v2.0.0
[1.0.0]: https://github.com/rspockframework/rspock/compare/0.2.5...1.0.0
[0.2.5]: https://github.com/rspockframework/rspock/compare/0.2.4...0.2.5
[0.2.4]: https://github.com/rspockframework/rspock/compare/0.2.3...0.2.4
[0.2.3]: https://github.com/rspockframework/rspock/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/rspockframework/rspock/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/rspockframework/rspock/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/rspockframework/rspock/compare/0.1.1...0.2.0
[0.1.1]: https://github.com/rspockframework/rspock/releases/tag/0.1.1
