# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Zero-width non-joiners are now stripped [#5](https://github.com/soundasleep/html2text_ruby/pull/5)
- MS Office (MsoNormal) documents are now rendered closer to actual render output
  - Note this assumes that the input MS Office document has standard `MsoNormal` CSS.
    This component is _not_ designed to try and interpret CSS within an HTML document.

### Changed
- Behaviour with multiple and nested `<p>`, `<div>` tags has been improved to be more in line with
  actual browser render behaviour (see test suite)

### Fixed
- Update nokogiri dependency to 1.8.5

## [0.2.1] - 2017-09-27
### Fixed
- Convert non-string input into strings [#3](https://github.com/soundasleep/html2text_ruby/pull/3)

[Unreleased]: https://github.com/soundasleep/html2text/compare/0.2.1...HEAD
[0.2.1]: https://github.com/soundasleep/html2text/compare/0.2.1...0.2.1
