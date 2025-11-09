# CHANGELOG

All notable changes to this project will be documented in this file.

This changelog's format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

> Important: See [source stability](https://github.com/apple/swift-mmio#source-stability) for details on major version "0".

## [Unreleased]

*No changes yet.*

<!--
Add new items at the end of the relevant section under **Unreleased**.
-->

---

## [0.1.1] - 2025-11-08

- Minor documention improvements.

The 0.1.1 release includes contributions from [rauhul]. Thank you!

## [0.1.0] - 2025-09-05

- Major feature release with new SVD tooling and API enhancements

### Additions

- Introduces `svd2swift` tool and SVD2SwiftPlugin for generating Swift MMIO
  interfaces from CMSIS System View Description (SVD) files. Supports manual
  command-line usage and automatic build-time generation via SwiftPM
  plugin. [#74]
- Adds SVD2LLDB plugin for improved debugging of MMIO registers using LLDB.
  Enables interaction with device registers by name rather than raw memory
  addresses, with visual decoding support. [#98]
- Adds support for SVD enumerated values, automatically generating bit field
  projections from SVD enumerations. Fully closed enumerations become Swift
  enums, others become structs with safer API access. [#119]
- Adds support for `as:` parameter in `@Reserved` bit field macro. [#147]
- Always exposes interposer API (previously hidden behind compilation flag) with
  deprecation warnings when not using `FEATURE_INTERPOSABLE`. [#164]
- Adds `Projection` associated type to `BitField` protocol, requiring
  conformance to `BitFieldProjectable`. Renames existing `insert`/`extract`
  methods to `insertBits`/`extractBits` and adds new typed variants. [#130]
- Conforms all standard integer types (`UInt8`, `UInt16`, `UInt32`, `UInt64`,
  `Int8`, `Int16`, `Int32`, `Int64`) to `BitFieldProjectable`. [#129]

### Changes

- Renames `@RegisterBank` macro to `@RegisterBlock` to avoid confusion with ARM
  register banking terminology. [#68]
- Updates to Swift 6.1 as minimum required version, with Swift 6.2 prerelease
  swift-syntax for macro expansion fixes. [#163]
- Major XML parsing performance improvements by replacing FoundationXML with
  libexpat, avoiding objc bridging allocations and using non-copyable array
  types. [#167]
- Generates SVD bit fields in LSB to MSB order for consistent Swift interfaces
  regardless of XML ordering. [#169]
- Reduces use of dynamic arrays to improve compatibility with Embedded Swift's
  no-allocations mode. [#172]
- Updates SVD2Swift to generate RegisterArrays and adds support for exporting
  clusters. [#116] [#114]
- Adds support for common protocols with SVD types. [#109]

### Fixes

- Fixes bug in `@ReadOnly(bits: ...)` macro which caused it to use the write
  only expansion. [#120]
- Fixes use of interpolated strings in Embedded Swift. [#124]
- Fixes handling of access levels in generated `.storage` properties. [#153]
- Prevents generation of empty projected types. [#148]
- Adds diagnostics for invalid bit field ranges. [#140] [#171]

The 0.1.0 release includes contributions from [ahoppen], [kubamracek],
[Kyle-Ye], [MaxDesiatov], [rauhul], [ShenghaiWang], and [ugurkoltuk]. Thank you!

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

[Unreleased]: https://github.com/apple/swift-mmio/compare/0.1.1...HEAD
[0.1.1]: https://github.com/apple/swift-mmio/releases/tag/0.1.1
[0.1.0]: https://github.com/apple/swift-mmio/releases/tag/0.1.0
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
[#68]: https://github.com/apple/swift-mmio/pull/68
[#74]: https://github.com/apple/swift-mmio/pull/74
[#75]: https://github.com/apple/swift-mmio/pull/75
[#79]: https://github.com/apple/swift-mmio/pull/79
[#81]: https://github.com/apple/swift-mmio/pull/81
[#98]: https://github.com/apple/swift-mmio/pull/98
[#109]: https://github.com/apple/swift-mmio/pull/109
[#114]: https://github.com/apple/swift-mmio/pull/114
[#116]: https://github.com/apple/swift-mmio/pull/116
[#119]: https://github.com/apple/swift-mmio/pull/119
[#120]: https://github.com/apple/swift-mmio/pull/120
[#124]: https://github.com/apple/swift-mmio/pull/124
[#129]: https://github.com/apple/swift-mmio/pull/129
[#130]: https://github.com/apple/swift-mmio/pull/130
[#140]: https://github.com/apple/swift-mmio/pull/140
[#147]: https://github.com/apple/swift-mmio/pull/147
[#148]: https://github.com/apple/swift-mmio/pull/148
[#153]: https://github.com/apple/swift-mmio/pull/153
[#163]: https://github.com/apple/swift-mmio/pull/163
[#164]: https://github.com/apple/swift-mmio/pull/164
[#165]: https://github.com/apple/swift-mmio/pull/165
[#167]: https://github.com/apple/swift-mmio/pull/167
[#169]: https://github.com/apple/swift-mmio/pull/169
[#171]: https://github.com/apple/swift-mmio/pull/171
[#172]: https://github.com/apple/swift-mmio/pull/172

<!-- Link references for contributors -->

[ahoppen]: https://github.com/apple/swift-mmio/commits?author=ahoppen
[kubamracek]: https://github.com/apple/swift-mmio/commits?author=kubamracek
[Kyle-Ye]: https://github.com/apple/swift-mmio/commits?author=Kyle-Ye
[MaxDesiatov]: https://github.com/apple/swift-mmio/commits?author=MaxDesiatov
[rauhul]: https://github.com/apple/swift-mmio/commits?author=rauhul
[SamHastings1066]: https://github.com/apple/swift-mmio/commits?author=SamHastings1066
[ShenghaiWang]: https://github.com/apple/swift-mmio/commits?author=ShenghaiWang
[ugurkoltuk]: https://github.com/apple/swift-mmio/commits?author=ugurkoltuk
