# Swift MMIO

**Swift MMIO** is an open source package for defining and operating on memory mapped IO directly in Swift. 

## Overview

Swift MMIO makes it easy to define registers directly in Swift source code and manipulate them in a safe and ergonomic manner.

## Example Usage

```swift
@RegisterBlock
struct Control {
  @RegisterBlock(offset: 0x0)
  var cr1: Register<CR1>
  @RegisterBlock(offset: 0x4)
  var cr2: Register<CR2>
}

@Register(bitWidth: 32)
struct CR1 {
  @ReadWrite(bits: 12..<13, as: Bool.self)
  var en: EN
}

let control = Control(unsafeAddress: 0x1000)
control.cr1.modify { $0.en = true }
```

## Using Swift MMIO in your project

Swift MMIO supports use with the Swift Package Manager. First, add the Swift MMIO repository to your Package's dependencies:

```swift
.package(url: "https://github.com/apple/swift-mmio", from: "0.1.0"),
```

Second, add the `MMIO` library to your target's dependencies:

```swift
.target(
  name: "DeviceRegisters",
  dependencies: [
    .product(name: "MMIO", package: "swift-mmio")
  ]),
```

Finally, `import MMIO` in your Swift source code.

### Source Stability 

This project follows semantic versioning. While still in major version `0`, source-stability is only guaranteed within minor versions (e.g. between `0.0.3` and `0.0.4`). If you want to guard against potentially source-breaking package updates, you can specify your package dependency using `.upToNextMinor(from: "0.0.2")` as the requirement:

```swift
.package(url: "https://github.com/apple/swift-mmio", .upToNextMinor(from: "0.1.0")),
```

## Documentation

For guides, articles, and API documentation see the [Package's documentation on the Web][docs] or in Xcode.

[docs]: https://swiftpackageindex.com/apple/swift-mmio/documentation/mmio

## Contributing to Swift MMIO

### Code of Conduct

Like all Swift.org projects, we would like the Swift MMIO project to foster a diverse and friendly community. We expect contributors to adhere to the [Swift.org Code of Conduct](https://swift.org/code-of-conduct/). A copy of this document is [available in this repository][coc].

[coc]: CODE_OF_CONDUCT.md

### Contact information

The current code owner of this package is Rauhul Varma ([@rauhul](https://github.com/rauhul)). You can contact him [on the Swift forums](https://forums.swift.org/u/rauhul/summary).

In case of moderation issues, you can also directly contact a member of the [Swift Core Team](https://swift.org/community/#community-structure).
