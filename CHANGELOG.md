# CHANGELOG

All notable changes to this project will be documented in this file.

This changelog's format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While still in major version `0`, source-stability is only guaranteed within
minor versions (e.g. between `0.0.3` and `0.0.4`). If you want to guard against
potentially source-breaking package updates, you can specify your package
dependency using `.upToNextMinor(from: "0.0.1")` as the requirement.

## [Unreleased]

*No changes yet.*

<!-- 
Add new items at the end of the relevant section under **Unreleased**.
-->

---

## [0.0.1] - 2023-11-17

- **Swift MMIO** initial release.

### Additions

- Introduces `@RegisterDescriptorBank` and `@RegisterDescriptorBank(offset:)` macros, enabling you
  to define register groups directly in Swift code. [#2]
- Introduces `@RegisterDescriptor` macro and bit field macros (`@Reserved`, `@ReadWrite`,
  `@ReadOnly`, `@WriteOnly`) for declaring registers composed of bit fields. Bit 
  field macros take a range parameter which describes the subset of bits they
  reference (e.g., `@ReadWrite(bits: 3..<7)`). [#4]
- Enhances bit field macros to support discontiguous bit fields. They now accept
  a variadic list of bit ranges and automatically handle scattering/gathering
  from the relevant bits (e.g., `@ReadWrite(bits: 3..<7, 10..<12)`). [#10]
- Enhances bit field macros with type projections via a new `as:` parameter.
  Projections allow you to operation on bit fields using strong types instead of
  raw integers (e.g. `@ReadWrite(bits: 3..<7, as: A.self)`) [#27]
- Enhances registers with support for interposing reads and writes when
  compiling with `FEATURE_INTERPOSABLE`. You can use interposers to unit test
  drivers. This feature is enabled when building with the
  `SWIFT_MMIO_FEATURE_INTERPOSABLE` environment variable defined. [#31]

The 0.0.1 release includes contributions from [rauhul]. Thank you!

<!-- Link references for releases -->

[Unreleased]: https://github.com/apple/swift-mmio/compare/0.0.1...HEAD
[0.0.1]: https://github.com/apple/swift-mmio/releases/tag/0.0.1

<!-- Link references for pull requests -->

[#2]: https://github.com/apple/swift-mmio/pull/2
[#4]: https://github.com/apple/swift-mmio/pull/4
[#10]: https://github.com/apple/swift-mmio/pull/10
[#27]: https://github.com/apple/swift-mmio/pull/27
[#31]: https://github.com/apple/swift-mmio/pull/31

<!-- Link references for contributors -->

[rauhul]: https://github.com/apple/swift-mmio/commits?author=rauhul
