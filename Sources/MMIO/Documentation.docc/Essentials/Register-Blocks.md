# Register Blocks

Organize and access groups of hardware registers using the RegisterBlock macro.

## Overview

In memory-mapped I/O, hardware peripherals like timers, communication interfaces (UART, SPI), or DMA controllers typically consist of multiple registers. These registers aren't standalone entities but are grouped together at a specific base memory address, forming what's known as a **register block**. Grouping registers this way provides a structured and organized view of a peripheral's control and status interface. Each register within the block is accessed via an offset from the block's base address.

> Note: This article assumes you have a basic understanding of what hardware registers are and how they are defined using the ``MMIO/Register(bitWidth:)`` macro. For an introduction to individual registers, please see <doc:Registers>.

### The @RegisterBlock macro

The ``MMIO/RegisterBlock()`` macro is fundamental for structuring memory-mapped hardware interfaces in Swift MMIO. It lets you define register blocks in a type-safe and declarative manner by applying it to a Swift `struct`. This `struct` then represents a hardware peripheral or a distinct, addressable block of registers within a larger peripheral.

The annotated `@RegisterBlock` type serves as a container for:
- Individual hardware registers, defined using ``MMIO/Register(bitWidth:)``, such as `Register<MyRegisterLayout>`.
- Nested register blocks, also defined using ``MMIO/RegisterBlock()``, to model sub-modules or grouped registers.
- Arrays of registers or register blocks, for repetitive hardware structures.

### Defining a simple register block

Let's explore how to define a register block by modeling a UART (Universal Asynchronous Receiver/Transmitter) peripheral — a common communication interface found in many embedded systems.

A typical UART peripheral contains several registers that control its operation:
- A data register for sending and receiving bytes.
- A status register that indicates conditions like "transmit buffer empty" or "receive buffer full".
- Control registers for configuring parameters like baud rate and communication settings.

Before you can define the complete UART peripheral structure, first define the layout of each individual register, using the ``MMIO/Register(bitWidth:)`` macro. For this example, assume you've already defined these registers:

```swift
import MMIO

// Register implementation omitted
@Register(bitWidth: 32) struct UARTData { ... }
@Register(bitWidth: 32) struct UARTStatus { ... }
@Register(bitWidth: 32) struct UARTControl { ... }
@Register(bitWidth: 32) struct UARTBaudRate { ... }
```

With the individual registers defined, create a structure that represents the entire UART peripheral. Define a Swift struct that represents the UART peripheral and annotate it with the ``MMIO/RegisterBlock()`` macro:

```swift
import MMIO

// Define the UART peripheral as a register block
@RegisterBlock
struct UARTPeripheral {
    // The struct body will contain properties for each register
}
```

Next, add properties for each register to your UART peripheral. Annotate each property with ``MMIO/RegisterBlock(offset:)`` to specify its memory offset from the peripheral's base address:

```swift
import MMIO

@RegisterBlock
struct UARTPeripheral {
    // The Data Register is at offset 0x00 from UARTPeripheral's base address.
    @RegisterBlock(offset: 0x00)
    var data: Register<UARTData>

    // The Status Register is at offset 0x04
    @RegisterBlock(offset: 0x04)
    var status: Register<UARTStatus>
    
    // Control register at offset 0x08
    @RegisterBlock(offset: 0x08)
    var control: Register<UARTControl>
    
    // Baud rate configuration at offset 0x0C
    @RegisterBlock(offset: 0x0C)
    var baudRate: Register<UARTBaudRate>
}
```

Each property's type is `Register<T>`, where `T` is the register struct you defined earlier. The `offset` parameter in the `@RegisterBlock` annotation specifies the byte offset of that register relative to the peripheral's base address. These offsets come from the hardware documentation for the specific UART peripheral you're working with.

### Using a register block

Now that you've defined your `UARTPeripheral` register block, let's explore how to use it to interact with the actual hardware.

The `@RegisterBlock` macro provides two important capabilities:
- It generates an `unsafeAddress` property to store the base memory address of the peripheral.
- It creates an initializer that takes this base address as a parameter.

To use this UART peripheral, first create an instance by providing the base memory address where the peripheral is mapped in the system's memory:

```swift
// Create an instance of the UART peripheral at its hardware memory address
let uart = UARTPeripheral(unsafeAddress: 0x40010000)
```

The `unsafeAddress` parameter (`0x40010000` in this example) represents the physical memory address where the UART peripheral's registers begin in the memory map. This address comes from your microcontroller's datasheet. The parameter is named `unsafeAddress` because it asserts the device can be found at the user-provided address, which the Swift language can't verify.

Once you have an instance of your register block, access its members using standard Swift property syntax:

```swift
// Access the data register
let dataRegister = uart.data

// Access the status register
let statusRegister = uart.status
```

When you access a property like `uart.data` or `uart.status`, Swift MMIO automatically calculates the correct memory address by adding the register's offset to the peripheral's base address:

- `uart.data` points to address `0x40010000 + 0x00 = 0x40010000`
- `uart.status` points to address `0x40010000 + 0x04 = 0x40010004`

### Nested register blocks

Hardware peripherals often group related registers together. Swift MMIO supports this organization through nested register blocks, allowing you to create hierarchical structures that match your hardware's design.

Let's enhance our UART example by grouping the control-related registers into their own block:

```swift
import MMIO

// Define a dedicated block for control-related registers
@RegisterBlock
struct UARTControlBlock {
    @RegisterBlock(offset: 0x00)
    var control: Register<UARTControl>

    @RegisterBlock(offset: 0x04)
    var baudRate: Register<UARTBaudRate>
}
```

Now incorporate this control block into the main UART peripheral:

```swift
@RegisterBlock
struct UARTPeripheral {
    @RegisterBlock(offset: 0x00)
    var data: Register<UARTData>

    @RegisterBlock(offset: 0x04)
    var status: Register<UARTStatus>

    // The UARTControlBlock is located at offset 0x08
    @RegisterBlock(offset: 0x08)
    var controlBlock: UARTControlBlock
}
```

The `@RegisterBlock(offset:)` macro works with both individual registers and other register blocks. When you access a register through a nested block, Swift MMIO automatically handles the address calculations:

```swift
// Create a UART instance at base address 0x40010000
let uart = UARTPeripheral(unsafeAddress: 0x40010000)

// Access the baud rate register through the nested block
let baudRate = uart.controlBlock.baudRate
```

`uart.controlBlock.baudRate` points to address: `0x40010000 + 0x08 + 0x04 = 0x4001000C`

### Working with repeated registers

Many hardware peripherals contain repeated register structures. For example, a GPIO peripheral typically has identical configuration registers for each pin, or a timer might have multiple identical channels. Swift MMIO provides the ``MMIO/RegisterArray`` type to efficiently model these repeated structures.

Let's enhance our UART example by adding support for multiple communication channels, where each channel has its own set of configuration registers:

```swift
import MMIO

// Register definition for a single channel's configuration
@Register(bitWidth: 32)
struct ChannelConfig {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var enable: ENABLE

    @ReadWrite(bits: 1..<3)
    var priority: PRIORITY

    @ReadWrite(bits: 3..<8)
    var mode: MODE
}
```

Now add an array of four channel configuration registers to the UART peripheral. Each register is 4 bytes apart from the next one, starting at offset 0x20:

```swift
@RegisterBlock
struct UARTPeripheral {
    @RegisterBlock(offset: 0x00)
    var data: Register<UARTData>

    @RegisterBlock(offset: 0x04)
    var status: Register<UARTStatus>

    @RegisterBlock(offset: 0x08)
    var controlBlock: UARTControlBlock

    @RegisterBlock(offset: 0x20, stride: 0x04, count: 4)
    var channels: RegisterArray<ChannelConfig>
}
```

The `channels` property has type ``MMIO/RegisterArray``, which is a type provided by Swift MMIO. Like Swift's standard arrays, you access elements using integer subscripts:

```swift
// Create a UART instance at base address 0x40010000
let uart = UARTPeripheral(unsafeAddress: 0x40010000)

// Access the configuration register for channel 2
let channel2 = uart.channels[2]
```

When you access an array element, Swift MMIO automatically calculates its memory address:
- `uart.channels[2]` points to address `0x40010000 + 0x20 + (2 * 0x04) = 0x40010028`

> Important: Swift MMIO performs bounds checking on array accesses. Attempting to access `uart.channels[4]` would trigger a runtime trap since we defined the array with `count: 4` (valid indices are 0-3).

Register arrays can contain either individual registers (as shown above) or entire register blocks, allowing you to model complex repeated structures like DMA channels, each with multiple registers.

## Topics

- ``MMIO/RegisterBlock()``
- ``MMIO/RegisterBlock(offset:)``
- ``MMIO/RegisterBlock(offset:stride:count:)``

- ``MMIO/Register``
- ``MMIO/RegisterArray``
