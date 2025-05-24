# ``MMIO``

Interact with memory-mapped I/O registers in embedded systems using type-safe, ergonomic, and efficient Swift code.

## Overview

Memory-Mapped I/O (MMIO) is a fundamental technique that enables software to control and monitor hardware components in embedded systems and other low-level environments. It involves mapping a peripheral's control, status, and data registers into the CPU's memory address space. This allows software to interact with hardware by simply reading from or writing to specific memory addresses.

Swift MMIO provides a robust, macro-driven framework to define these hardware interfaces safely in Swift, bringing strong type safety, clarity, and modern language features to low-level hardware programming.

With Swift MMIO, you can:
- **Define Complex Register Layouts:** Declaratively describe hardware interfaces using ``MMIO/RegisterBlock()`` and ``MMIO/Register(bitWidth:)``. See <doc:Defining-Registers> and <doc:Register-Layouts>.
- **Specify Bit Fields Precisely:** Define individual bit fields, their positions, widths, and access permissions using macros like ``MMIO/ReadWrite(bits:as:)``. See <doc:Bit-Fields>.
- **Leverage Type Projections:** Work with bit fields as meaningful Swift types (like `Bool` or custom enums and structs) via ``MMIO/BitFieldProjectable``. See <doc:Type-Projections>.
- **Ensure Correct Memory Semantics:** All register accesses automatically use `volatile` memory semantics. See <doc:Volatile-Access>.
- **Handle Complex Hardware Structures:** Model arrays of registers or register blocks (``MMIO/RegisterArray``) and discontiguous bit fields. See <doc:Register-Arrays> and <doc:Discontiguous-Bit-Fields>.
- **Facilitate Unit Testing:** Use an optional interposer mechanism (``MMIO/MMIOInterposer``) to mock hardware for off-target testing. See <doc:Testing-With-Interposers>.

@Metadata {
    @CallToAction(purpose: "primary", label: "View on GitHub", url: "https://github.com/apple/swift-mmio")
}

### FIXME: overview of sections in catalog

> talk about the overall structure "Register Block -> Register -> Bit Field"
>
> talk about "Registers" and "Hierarchies" suggest using SVD2Swift instead of manually defining them.

FIXME: find a new home for this:

### Automating Definitions with SVD2Swift

Before manually defining registers, especially for complex microcontrollers, it's highly recommended to use the `SVD2Swift` tool provided with Swift MMIO. CMSIS-SVD files are XML-based descriptions of a microcontroller's memory map and peripherals, often supplied by hardware vendors or maintained by the community.

`SVD2Swift` parses these files and automatically generates the corresponding Swift MMIO struct definitions. Using `SVD2Swift` offers significant advantages:
- **Reduce Errors:** Manual transcription of register addresses, bit field offsets, and widths from datasheets is tedious and error-prone. `SVD2Swift` automates this, leading to more accurate definitions.
- **Save Time:** For peripherals with many registers and bit fields, `SVD2Swift` can generate the necessary Swift code in seconds, a task that might take hours or days to do manually.
- **Leverage Vetted Sources:** Since SVD files are often vendor-provided or community-vetted, the generated code is based on a more reliable source of truth than manual interpretation alone.

While understanding the manual definition process described below is valuable, `SVD2Swift` should be your primary approach for generating register maps whenever SVD files are available for your target hardware. See [SVD2Swift](https://swiftpackageindex.com/apple/swift-mmio/main/documentation/svd2swift) for details.


## Topics

### Essentials

- <doc:Installation>
- <doc:Bit-Fields>
- <doc:Registers>
- <doc:Register-Blocks>

### Core Concepts

- <doc:Understanding-MMIO>
- <doc:Volatile-Access>

### Advanced Topics

- <doc:Type-Projections>
- <doc:Testing-With-Interposers>
- <doc:Safety-Considerations>

- ``MMIO/BitFieldProjectable``
- ``MMIO/MMIOInterposer``
