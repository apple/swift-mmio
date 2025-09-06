# ``MMIO``

@Metadata {
  @CallToAction(
    url: "https://github.com/apple/swift-mmio",
    purpose: link,
    label: "View on Github")
}

Interact with memory-mapped I/O registers in embedded systems using type-safe, ergonomic, and efficient Swift code.

## Overview

Memory-Mapped I/O (MMIO) is a fundamental technique that enables software to control and monitor hardware components in embedded systems and other low-level environments. It involves mapping a peripheral's control, status, and data registers into the CPU's memory address space. This allows software to interact with hardware by simply reading from or writing to specific memory addresses.

Swift MMIO provides a robust, macro-driven framework to define these hardware interfaces safely in Swift, bringing strong type safety, clarity, and modern language features to low-level hardware programming.

With Swift MMIO, you can:

- **Define Register Layouts:** Declaratively describe hardware interfaces using ``MMIO/Register(bitWidth:)`` and ``MMIO/RegisterBlock()``. See <doc:Registers> and <doc:Register-Blocks>.
- **Specify Bit Fields:** Define individual bit fields, their positions, widths, and access permissions using macros like ``MMIO/ReadWrite(bits:as:)``. See <doc:Registers>.
- **Leverage Type Projections:** Work with bit fields as meaningful Swift types (like `Bool` or custom enums and structs) via ``MMIO/BitFieldProjectable``. See <doc:Registers>.
- **Facilitate Unit Testing:** Use an optional interposer mechanism (``MMIO/MMIOInterposer``) to mock hardware for off-target testing. See <doc:Testing-With-Interposers>.

### Documentation Structure

Swift MMIO documentation is organized into three main sections:

1. **Essentials**: Core concepts and setup instructions to get you started quickly.
   - <doc:Installation> guides you through adding Swift MMIO to your project.
   - <doc:Registers> explains how to define and interact with individual hardware registers.
   - <doc:Register-Blocks> shows how to organize registers into structured peripheral interfaces.
2. **Core Concepts**: Fundamental principles behind memory-mapped I/O.
   - <doc:Understanding-MMIO> provides an overview of memory-mapped I/O principles.
   - <doc:Volatile-Access> explains why specialized memory access is needed for hardware registers.
3. **Advanced Topics**: More sophisticated features for complex scenarios.
   - <doc:Custom-BitFieldProjectable> demonstrates how to map bit fields to meaningful Swift types.
   - <doc:Testing-With-Interposers> shows how to test hardware interaction code without physical devices.
   - <doc:Safety-Considerations> outlines Swift MMIO's safety guarantees and developer responsibilities.

### Automating Definitions with SVD2Swift

Before manually defining registers, especially for complex microcontrollers, it's highly recommended to use the `SVD2Swift` tool provided with Swift MMIO. CMSIS-SVD files are XML-based descriptions of a microcontroller's memory map and peripherals, often supplied by hardware vendors or maintained by the community.

`SVD2Swift` parses these files and automatically generates the corresponding Swift MMIO struct definitions. Using `SVD2Swift` offers significant advantages:

- **Reduce Errors:** Manual transcription of register addresses, bit field offsets, and widths from datasheets is tedious and error-prone. `SVD2Swift` automates this, leading to more accurate definitions.
- **Save Time:** For peripherals with many registers and bit fields, `SVD2Swift` can generate the necessary Swift code in seconds, a task that might take hours or days to do manually.
- **Leverage Vetted Sources:** Since SVD files are often vendor-provided or community-vetted, the generated code is based on a more reliable source of truth than manual interpretation alone.

While understanding the manual definition process is valuable, `SVD2Swift` should be your primary approach for generating register maps whenever SVD files are available for your target hardware. See [SVD2Swift](https://swiftpackageindex.com/apple/swift-mmio/main/documentation/svd2swift) for details.

### Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

### Essentials

- <doc:Installation>
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
- ``MMIO/MMIOInterposer``
