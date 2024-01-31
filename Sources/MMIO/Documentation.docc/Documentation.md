# ``MMIO``

Define and operate on memory mapped IO.

## Overview

Swift MMIO makes it easy to define registers directly in Swift source code and manipulate them in a safe and ergonomic manner.

> Note: Documentation under construction...

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

## Using MMIO in your project

`MMIO` supports use with the Swift Package Manager. First, add the Swift MMIO repository to your Package's dependencies:

```swift
.package(url: "https://github.com/apple/swift-mmio.git", from: "0.0.2"),
```

> Important: See [source stability](https://github.com/apple/swift-mmio#source-stability) for details on major version "0".

Second, add the `MMIO` library to your target's dependencies:

```swift
.target(
  name: "DeviceRegisters",
  dependencies: [
    .product(name: "MMIO", package: "swift-mmio")
  ]),
```

Finally, `import MMIO` in your Swift source code.

## Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.
