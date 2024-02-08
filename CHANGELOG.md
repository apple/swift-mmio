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

## [0.0.2] - 2024-02-07

- Quality of life improvements

### Additions

- Adds a variant of the `@RegisterBank` macro with offset, stride, and count
  arguments. This allows you to declare a logical vector of registers with a
  user-defined stride between them, e.g.
  `@RegisterBank(offset: 0x100, stride: 0x10, count: 0x8)`. [#65]
- Adds a variant of `Register.write` taking a builder closure:
  `write<T>(_: (inout Value.Write) -> (T)) -> T`. This method allows you to form
  a write value without needing to create a named temporary value. [#75]
- Adds conditional extension to `RawRepresentable` types conforming to
  `FixedWidthInteger` for easier adoption of `BitFieldProjectable`. Conforming
  types only need to provide an implementation for `bitWidth`. [#81]

### Changes

- Updates bit-field macros bits parameter to be generic over `BinaryInteger`
  `RangeExpression`s. You can now specify bit ranges using any Swift range
  syntax, e.g. `0..<1`, `0...1`, `0...`, `...1`, or `...`. [#43]
- Updates the MMIOVolatile bridge to eliminate the dependency on `stdint.h`,
  allowing you to build needing a copy of libc headers. [#52]
- Removes restrictions on computed properties for `@RegisterBank` and
  `@Register` macros. [#59]
- Updates error messages for members missing a macro annotation to include
  fix-its. [#64]

### Fixes

- Replaces the use of `hasFeature(Embedded)` with `$Embedded` for proper
  compilation condition checking. [#60]
- Corrects the generation of placeholder attributes for Macros with multiple
  arguments, ensuring proper commas between the arguments. [#63]
- Resolves build issues for 32-bit platforms, ensuring compatibility with
  watchOS. The use of 64-bit wide integers is now conditionally compiled based
  on target architecture. [#79]

The 0.0.2 release includes contributions from [rauhul] and [SamHastings1066].
Thank you!

## [0.0.1] - 2023-11-17

- **Swift MMIO** initial release.

### Additions

- Introduces `@RegisterBank` and `@RegisterBank(offset:)` macros, enabling you
  to define register groups directly in Swift code. [#2]
- Introduces `@Register` macro and bit field macros (`@Reserved`, `@ReadWrite`,
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

[Unreleased]: https://github.com/apple/swift-mmio/compare/0.0.2...HEAD
[0.0.2]: https://github.com/apple/swift-mmio/releases/tag/0.0.2
[0.0.1]: https://github.com/apple/swift-mmio/releases/tag/0.0.1

<!-- Link references for pull requests -->

[#2]: https://github.com/apple/swift-mmio/pull/2
[#4]: https://github.com/apple/swift-mmio/pull/4
[#10]: https://github.com/apple/swift-mmio/pull/10
[#27]: https://github.com/apple/swift-mmio/pull/27
[#31]: https://github.com/apple/swift-mmio/pull/31
[#43]: https://github.com/apple/swift-mmio/pull/43
[#52]: https://github.com/apple/swift-mmio/pull/52
[#59]: https://github.com/apple/swift-mmio/pull/59
[#60]: https://github.com/apple/swift-mmio/pull/60
[#63]: https://github.com/apple/swift-mmio/pull/63
[#64]: https://github.com/apple/swift-mmio/pull/64
[#65]: https://github.com/apple/swift-mmio/pull/65
[#75]: https://github.com/apple/swift-mmio/pull/75
[#79]: https://github.com/apple/swift-mmio/pull/79
[#81]: https://github.com/apple/swift-mmio/pull/81

<!-- Link references for contributors -->

[rauhul]: https://github.com/apple/swift-mmio/commits?author=rauhul
[SamHastings1066]: https://github.com/apple/swift-mmio/commits?author=SamHastings1066
