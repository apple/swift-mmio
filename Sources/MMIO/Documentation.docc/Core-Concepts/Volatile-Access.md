# Understanding Volatile Memory Access

Learn why specialized memory access is needed when you interact with hardware registers.

## Overview

When software interacts with hardware registers through Memory-Mapped I/O (MMIO), the way memory is accessed becomes critical. Compilers employ sophisticated optimizations that, while beneficial for general-purpose code, can lead to incorrect behavior when applied to MMIO operations. Understanding "volatile" memory access helps explain why these special considerations are necessary.

### The challenge of compiler optimizations

Modern compilers are designed to make programs run faster and use less memory. To achieve this, they perform various optimizations, such as:

- term **Reordering instructions**: The compiler might change the order of memory reads and writes if it determines that the program's observable outcome (based on standard memory models) will remain the same.

- term **Eliminating redundant accesses**: If the compiler sees code that writes a value to a memory location and then immediately reads it back without any intervening use of that value, it might optimize away the read, assuming the value hasn't changed. Similarly, multiple writes to the same location without intermediate reads might be coalesced.

- term **Caching values**: Values read from memory might be temporarily stored in CPU registers for faster subsequent access. The compiler assumes that the memory location won't change unless the program itself writes to it.

These optimizations are highly effective for operations on standard RAM. However, MMIO registers behave differently from regular memory.

### Why memory mapped registers are special

MMIO registers are direct interfaces to hardware components, and their behavior is tied to the hardware's state and actions:

- term **Reads can have side effects**: Reading from certain registers can alter the hardware's state. For example, reading a status register in a UART (Universal Asynchronous Receiver-Transmitter) might clear an "interrupt pending" flag. Reading a data register from a sensor might retrieve a new measurement and prepare the sensor for the next one. If the compiler optimizes away such a read, a critical hardware interaction could be missed.

- term **Writes trigger hardware actions**: Writing to a control register can initiate hardware operations, such as starting a timer, changing the state of a GPIO pin, or beginning a data transmission over SPI (Serial Peripheral Interface).

- term **Register values can change asynchronously**: Hardware can update a status register (for example, an ADC conversion-complete flag, or a network packet-received flag) at any moment, independent of the CPU's execution flow. If the compiler caches a previously read value of such a register, the software will operate on stale data, missing important hardware events.

- term **Order of operations matters**: Configuring a peripheral often involves writing to multiple registers in a specific sequence. If the compiler reorders these writes, the peripheral might be configured incorrectly or enter an unexpected state.

If standard compiler optimizations are applied to MMIO accesses, these unique characteristics can lead to severe bugs that are often difficult to diagnose.

### The "volatile" concept

To prevent these issues, programming languages that are often used for low-level development (like C and C++) provide a mechanism to inform the compiler that a particular memory access must not be optimized in the ways described above. This is typically achieved using the `volatile` keyword when declaring a pointer or variable that refers to an MMIO register.

A `volatile` qualifier essentially instructs the compiler:

- term **Preserve all accesses**: Every read or write operation specified in the source code must be performed. Do not eliminate any access.

- term **Maintain relative order**: The sequence of volatile accesses, as written in the code, must be maintained relative to other volatile accesses.
  > Note: Non-volatile accesses around volatile ones might still be reordered by the compiler.)

- term **Do not cache**: For a read, always fetch the value directly from the memory location. For a write, always write the value directly to the memory location. Do not rely on values cached in CPU registers from previous reads.

### Volatile access in Swift MMIO

Swift, designed as a high-level, safe language, does not expose a direct `volatile` keyword for arbitrary memory pointers in the same way C does for general Swift code. To ensure correct MMIO behavior, Swift MMIO employs a strategy based on C interoperation.

The Swift MMIO package includes a minimal C module (named `MMIOVolatile`). This module provides simple C functions dedicated to performing volatile loads and stores for various fixed-width integer types (e.g., `mmio_volatile_load_uint32_t`, `mmio_volatile_store_uint32_t`). These C functions use the C language's `volatile` keyword to guarantee the necessary memory semantics.

When you use methods like ``MMIO/Register/read()``, ``MMIO/Register/write(_:)->()``, or ``MMIO/Register/modify(_:)-7p198`` provided by Swift MMIO, these methods internally call the appropriate C functions from `MMIOVolatile` for each hardware access.

It's particularly important to understand how this applies to the `modify { ... }` operation. The `modify` method performs one volatile read of the register before the closure is executed, and one volatile write of the (potentially modified) value after the closure completes. Operations on the `Write` view *inside* the closure are applied to an in-memory copy of the register's state and do not individually trigger volatile hardware accesses. This design ensures that the entire read-modify-write sequence for the register update is performed as a single set of carefully controlled volatile operations. This approach inherently avoids certain common pitfalls where multiple, unintended read-modify-write sequences might occur, a topic explored further in <doc:Safety-Considerations>.

#### Conceptual Example

A Swift MMIO operation like:

```swift
// Reads a 32-bit register value
let value = myRegister.read().raw.storage
```

is conceptually equivalent to invoking a C function like:

```c
// Simplified C equivalent in MMIOVolatile.h
uint32_t mmio_volatile_load_uint32_t(const volatile uint32_t *pointer) {
    return *pointer; // This dereference is volatile
}
```
