# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [UNRELEASED]
### Added
- Interaction-based testing: Mock with expectations in the Then block.

### Changed
- Test names now have the test index and line number as suffix instead of prefix.
- Cleanup transformed code output.

### Fixed
- Fixed source mapping for transformed assertion nodes.

## [0.2.5] 2019-05-28
### Fixed
- Fixed BacktraceFilter so that source mapping works again

## [0.2.4] 2019-05-27
### Changed
- Bump Unparser dependency from ~> 0.2.8 to ~> 0.4

## [0.2.3] 2018-11-09
### Fixed
- Cleanup block can now contain more than one node

## [0.2.2] 2018-11-08
### Changed
- Extracted ASTTransform to its own gem: `ast_transform`

## [0.2.1] 2018-10-09
### Added
- _line_number_ is now displayed in the test name, and is available in test scope for debugging purposes

### Changed
- Renamed test_index to _test_index_

## [0.2.0] 2018-09-21
### Added
- Truth table generator Rake task.

## [0.1.1] 2018-09-19
### Initial Release!