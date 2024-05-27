# ``SVD``

A library for working with CMSIS SVD files.

## Overview

[CMSIS](https://www.arm.com/technologies/cmsis) (Common Microcontroller Software Interface Standard) [SVD](https://arm-software.github.io/CMSIS_5/SVD/html/index.html) (System View Description) is a standardized XML file format used to describe the hardware characteristics of a microcontroller or processor. The format provides essential information about the interrupts, memory-mapped registers, and other hardware components of a device.

`SVD` makes it easy to parse and operate on SVD files in Swift and is tested to work against a corpus of nearly 2000 files. 

This library is intended to enable development of _tooling_ surrounding SVD files and not intended to be directly used by firmware.

## Tools built with SVD

- `svd2swift`: Generate swift-mmio register interfaces from SVD files.
- `SVD2SwiftPlugin`: A SwiftPM build plugin for running `svd2swift` at build time.
- `SVD2LLDB`: An lldb plugin for interacting with registers in a debug session by name.

## Using SVD in your project

`SVD` supports use with the Swift Package Manager. First, add the Swift MMIO repository to your Package's dependencies:

```swift
.package(url: "https://github.com/apple/swift-mmio.git", from: "0.0.2"),
```

> Important: See [source stability](https://github.com/apple/swift-mmio#source-stability) for details on major version "0".

Second, add the `SVD` library to your target's dependencies:

```swift
.executableTarget(
  name: "MySVDTool",
  dependencies: [
    .product(name: "SVD", package: "swift-mmio")
  ]),
```

Finally, `import SVD` in your Swift source code.

```swift
import SVD

// Load a file from a url.
let svdData = try Data(contentsOf: ...)

// Decode raw data into SVD types.
let svdDevice = try SVDDevice(svdData: svdData)

// Print the device's name
print(svdDevice.name)
```

## Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

### Core Types

- ``SVDDevice``
- ``SVDPeripheral``
- ``SVDCluster``
- ``SVDRegister``
- ``SVDField``
