# ``MMIO``

@Metadata {
  @CallToAction(
    url: "https://github.com/apple/swift-mmio",
    purpose: link,
    label: "View on GitHub")
}

Type-safe Swift bindings for memory-mapped I/O registers in embedded systems.

## Overview

Memory-Mapped I/O (MMIO) is a fundamental technique that enables software to control hardware components by mapping a peripheral's control, status, and data registers into the CPU's memory address space. This allows software to interact with hardware by simply reading from or writing to specific memory addresses.

Swift MMIO provides a robust, macro-driven framework to define these hardware interfaces safely in Swift, bringing strong type safety, clarity, and modern language features to low-level hardware programming.

### Automating Definitions with SVD2Swift

Use `SVD2Swift` (included with Swift MMIO) to generate register definitions from CMSIS-SVD files when available. CMSIS-SVD files are XML-based descriptions of a microcontroller's memory map, supplied by hardware vendors or maintained by the community. `SVD2Swift` parses these files and generates the corresponding Swift MMIO struct definitions.

While understanding the manual definition process is valuable, `SVD2Swift` should be your primary approach for generating register maps whenever SVD files are available for your target hardware. See [SVD2Swift](https://swiftpackageindex.com/apple/swift-mmio/main/documentation/svd2swift) for details.

### Contributing

Contributions and feedback are welcome. Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

### Essentials

- <doc:Installation>
- <doc:Getting-Started>
- <doc:Registers>
- <doc:Register-Blocks>

### Core Concepts

- <doc:Understanding-MMIO>
- <doc:Volatile-Access>

### Advanced Topics

- <doc:Custom-BitFieldProjectable>
- <doc:Testing-With-Interposers>
- <doc:Safety-Considerations>

- ``MMIO/BitFieldProjectable``
- ``MMIO/BitRangeExpression``
- ``MMIO/MMIOInterposer``
