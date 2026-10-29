# Understanding Volatile Memory Access

Learn how compiler optimizations can break hardware register access, and how volatile access prevents this.

## Overview

Compilers remove, merge, and reorder memory accesses to make code faster. These changes are safe for ordinary RAM, but they can break code that accesses hardware registers.

This article assumes that you know what registers and bit fields are. For an introduction, see <doc:Understanding-MMIO>.

### An example of the problem

The following C code waits until hardware sets bit 0 of a status register. It uses a plain pointer, without `volatile`:

```c
// A plain pointer to a status register
uint32_t *status = (uint32_t *)0x40002000;

// Wait until the hardware sets the READY bit (bit 0)
while ((*status & 0x1) == 0) {
    // Do nothing
}
```

Nothing in the loop writes to `*status`, so the compiler can assume that the value doesn't change. It can load the value one time, before the loop starts. If the bit is `0` at that time, the loop never ends, even after the hardware sets the bit. Because the loop has no side effects, the compiler can also remove the loop completely.

### How compilers optimize memory access

To make programs faster and smaller, compilers change the memory accesses that the source code specifies. For example:

- term **Reordering accesses**: The compiler might change the order of memory reads and writes if it determines that the program's observable outcome won't change.
- term **Eliminating redundant accesses**: If a program writes a value and then reads it back with no access between them, the compiler might remove the read. Repeated reads with no write between them can become one read, and the compiler can remove a write that a later write replaces.
- term **Merging and splitting accesses**: The compiler can merge adjacent accesses into one wider access, or split an access into narrower ones.

These optimizations are correct for ordinary RAM. Registers behave differently.

### Why registers are different from RAM

MMIO registers are direct interfaces to hardware components, and their behavior is tied to the hardware's state and actions:

- term **Reads can have side effects**: Reading certain registers can alter the hardware's state. For example, reading a UART status register might clear an "interrupt pending" flag. Reading a sensor's data register might retrieve a measurement and prepare the sensor for the next one. If the compiler optimizes away the read, hardware interactions could be missed.
- term **Writes trigger hardware actions**: Writing to a control register can initiate hardware operations, such as starting a timer, changing the state of a GPIO pin, or beginning a data transmission over SPI.
- term **Register values can change asynchronously**: Hardware can update status registers (such as ADC conversion-complete flags or packet-received flags) at any time, independent of the CPU's execution. If the compiler caches a previously read value, the software operates on stale data and misses hardware events.
- term **Order of operations matters**: Configuring a peripheral often requires writing to multiple registers in a specific sequence. If the compiler reorders these writes, the peripheral can be misconfigured or enter an unexpected state.

If the compiler applies its usual optimizations to register accesses, your program can miss hardware events or configure a peripheral incorrectly. These bugs are often difficult to find.

### What volatile does

C and C++ have the `volatile` keyword for memory locations like these. In the earlier example, a `volatile uint32_t *` pointer makes the compiler load the register again on each pass through the loop.

The `volatile` qualifier tells the compiler:

- term **Preserve all accesses**: Every read or write operation specified in the source code must be performed. Do not eliminate any access.
- term **Maintain relative order**: The sequence of volatile accesses, as written in the code, must be maintained relative to other volatile accesses. The compiler can still move non-volatile accesses past volatile ones.
- term **Don't reuse earlier values**: Always load the value from the address, and always store the value to the address. Don't keep the value from an earlier read in a CPU register.

> Important: `volatile` controls only what the compiler does. It doesn't:
> - Bypass the CPU's data cache, a small and fast copy of memory in the CPU. Whether an access uses a cache depends on the memory type of the address range, which the architecture and its memory protection settings define.
> - Add memory barrier instructions, which make the CPU complete earlier memory accesses before later ones. Whether the CPU can reorder accesses depends on the architecture and the memory type of the address range.
> - Make a read-modify-write sequence atomic, that is, done as one step that nothing else can interrupt. An interrupt, another CPU core, a direct memory access (DMA) transfer, or the hardware itself can change the register between the read and the write.

Swift MMIO doesn't add barrier instructions either. For example, plain stores to a buffer in RAM can move after a volatile store that starts a DMA transfer of that buffer. Use the barriers that your architecture requires.

### Volatile access in Swift MMIO

Swift has no `volatile` keyword. Loads and stores through `UnsafePointer` and `UnsafeMutablePointer` are plain memory accesses, so the Swift compiler can make the same optimizations as in the C example. To make volatile accesses, Swift MMIO uses C interoperation.

Swift MMIO includes a small C module, `MMIOVolatile`, with one volatile load function and one volatile store function for each integer width, such as `mmio_volatile_load_uint32_t` and `mmio_volatile_store_uint32_t`. These functions use C's `volatile` keyword to make the compiler keep each access, in order.

When you use methods like ``MMIO/Register/read()``, ``MMIO/Register/write(_:)->()``, or ``MMIO/Register/modify(_:)-((Value.Read,Value.Write)->(T))``, these methods call the appropriate `MMIOVolatile` C functions. Each call to `read` performs exactly one volatile load, and each call to `write` performs exactly one volatile store. If a register has an interposer, the interposer receives each access in place of the hardware, and no volatile access occurs. See <doc:Testing-With-Interposers>.

In Swift MMIO, the polling loop from the example looks like this:

```swift
@Register(bitWidth: 32)
struct Status {
    @ReadOnly(bits: 0, as: Bool.self)
    var ready: READY
}

let status = Register<Status>(unsafeAddress: 0x4000_2000)

// Each pass through the loop calls read(), which performs one volatile load
while !status.read().ready {
    // Do nothing
}
```

For this 32-bit register, each call to `read()` calls `mmio_volatile_load_uint32_t`, which is equivalent to this C function:

```c
// Simplified C equivalent in MMIOVolatile.h
uint32_t mmio_volatile_load_uint32_t(const volatile uint32_t *pointer) {
    return *pointer; // This dereference is volatile
}
```

The `modify` method performs one volatile read before it runs your closure, and one volatile write after the closure returns. Changes to the value inside the closure apply to a local copy, usually in CPU registers, so they don't access the hardware. So the full read-modify-write sequence is one volatile read and one volatile write, not one sequence for each field that you change. For problems that can occur when more than one read-modify-write sequence accesses a register, see <doc:Safety-Considerations>.
