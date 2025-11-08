# Understanding Volatile Memory Access

Learn why specialized memory access is needed when you interact with hardware registers.

## Overview

When interacting with hardware registers through MMIO, memory access semantics become critical. Compilers use optimizations that work well for general code but can break MMIO operations. Hardware registers need special treatment to prevent these optimizations.

### The challenge of compiler optimizations

Modern compilers are designed to make programs run faster and use less memory. To achieve this, they perform various optimizations, such as:

- term **Reordering instructions**: The compiler might change the order of memory reads and writes if it determines the program's observable outcome (based on standard memory models) won't change.

- term **Eliminating redundant accesses**: If a program writes a value to a memory location and immediately reads it back without intervening use, the compiler might eliminate the read, assuming the value hasn't changed. Similarly, multiple reads or writes to the same location without intermediate reads might be coalesced into one.

These optimizations are highly effective for operations on standard RAM. However, MMIO registers behave differently from regular memory.

### Why memory mapped registers are special

MMIO registers are direct interfaces to hardware components, and their behavior is tied to the hardware's state and actions:

- term **Reads can have side effects**: Reading certain registers can alter the hardware's state. For example, reading a UART status register might clear an "interrupt pending" flag. Reading a sensor's data register might retrieve a measurement and prepare the sensor for the next one. If the compiler optimizes away the read, hardware interactions could be missed.

- term **Writes trigger hardware actions**: Writing to a control register can initiate hardware operations, such as starting a timer, changing the state of a GPIO pin, or beginning a data transmission over SPI.

- term **Register values can change asynchronously**: Hardware can update status registers (like ADC conversion-complete flags or packet-received flags) at any time, independent of the CPU's execution. If the compiler caches a previously read value, the software operates on stale data and misses hardware events.

- term **Order of operations matters**: Configuring a peripheral often requires writing to multiple registers in a specific sequence. If the compiler reorders these writes, the peripheral can be misconfigured or enter an unexpected state.

If standard compiler optimizations are applied to MMIO accesses, these unique characteristics can lead to severe bugs that are often difficult to diagnose.

### The "volatile" concept

To prevent these issues, low-level programming languages like C and C++ provide the `volatile` keyword. The `volatile` keyword instructs the compiler that a particular memory locations must be treated more carefully.

The `volatile` qualifier tells the compiler:

- term **Preserve all accesses**: Every read or write operation specified in the source code must be performed. Do not eliminate any access.

- term **Maintain relative order**: The sequence of volatile accesses, as written in the code, must be maintained relative to other volatile accesses.
  > Note: The compiler can still reorder non-volatile accesses around volatile ones.

- term **Do not cache**: Always read directly from memory. Always write directly to memory. Don't use cached values from previous reads.

### Volatile access in Swift MMIO

Swift, designed as a high-level, safe language, doesn't expose a `volatile` keyword for arbitrary memory pointers like C does. To ensure correct MMIO behavior, Swift MMIO uses C interoperation.

The Swift MMIO package includes a minimal C module called `MMIOVolatile`. This module provides simple C functions dedicated to performing volatile loads and stores for various fixed-width integer types (e.g. `mmio_volatile_load_uint32_t`, `mmio_volatile_store_uint32_t`, etc.). These functions use C's `volatile` keyword to guarantee the necessary memory semantics.

When you use methods like ``MMIO/Register/read()``, ``MMIO/Register/write(_:)->()``, or ``MMIO/Register/modify(_:)``, these methods call the appropriate `MMIOVolatile` C functions.

It's particularly important to understand how this applies to the `modify { ... }` operation. The `modify` method performs one volatile read before the closure is executed, and one volatile write of the value after the closure completes. Operations on the `Write` view *inside* the closure are applied to an in-cpu-memory copy of the register's value and don't individually trigger volatile hardware accesses. This ensures the entire read-modify-write sequence is performed as a *single pair* of volatile operations, avoiding common pitfalls from unintended multiple read-modify-write sequences (see <doc:Safety-Considerations> for details).

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
