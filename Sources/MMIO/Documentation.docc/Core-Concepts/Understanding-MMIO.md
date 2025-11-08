# Understanding Memory-Mapped I/O

Learn how you can communicate with hardware devices.

## Overview

With memory-mapped I/O (MMIO), you interact with hardware peripherals using regular memory operations. Hardware devices like timers, UARTs, GPIO controllers, and SPI controllers get mapped to specific addresses in the CPU's memory space.

You control hardware by reading from and writing to these memory addresses, using the same load and store instructions used for RAM. This is different from Port-Mapped I/O, which uses dedicated I/O instructions.

For instance, if a GPIO peripheral has a "Data Output Register" at memory address `0x400FF000`, the CPU could set the third pin of this port high (assuming pin 3 corresponds to bit 3 of the register) by writing the value `0x00000008` (which is binary `...00001000`) to that address.

### Registers

In the context of MMIO, a **register** is a small, fixed-size storage location within a hardware peripheral. Each register serves a specific purpose:

- **Control Registers:** Configure the behavior of the peripheral. Examples include enabling or disabling features, setting operational modes, or selecting clock sources.
- **Status Registers:** Reflect the current state of the peripheral, such as whether an operation is complete, an error has occurred, or data is ready. These are often read-only, and specific bits might be cleared automatically upon reading (a "read-to-clear" mechanism).
- **Data Registers:** Transfer data to or from the peripheral. For example, writing a byte to a UART transmit data register sends it over the serial line, while reading an Analog-to-Digital Converter (ADC) result register retrieves the latest conversion value.

Registers are typically 8, 16, 32, or 64 bits wide, aligning with the processor's data bus width or common data sizes. The precise address, layout, and behavior of each register for a microcontroller are detailed in its **reference manual** or **datasheet**. This document is the authoritative source for understanding a peripheral's register structure. The datasheet also specifies critical details like the reset value of each register (its state after a system reset).

Swift MMIO uses the ``MMIO/Register`` macro to define the structure and properties of individual registers based on this hardware documentation.

@Comment {
> FIXME: registers are always read/written a single contiguous unit and individual fields within them cannot be mutated independently of the others. THIS isn't precise enough phrasing and is confusing.
}

### Bit fields

Hardware registers are usually divided into smaller **bit fields**, where each field controls or represents a specific piece of information.

For example, a 32-bit Timer Control Register (`TIMER_CTRL`) might be structured:

| Bits    | Name         | Description                            | Access Type        |
|:--------|:-------------|:-------------------------------------- |:-------------------|
| 0       | `EN`         | Timer Enable                           | Read/Write         |
| 1       | `INT_EN`     | Interrupt Enable                       | Read/Write         |
| 2-3     | `MODE`       | Timer Mode Select                      | Read/Write         |
| 4-7     | _Reserved_   | (Unused)                               | -                  |
| 8       | `OVF_FLAG`   | Overflow Flag                          | Read-Only          |
| 9       | `OVF_CLR`    | Clear Overflow Flag (Write 1 to Clear) | Write-Only (W1C)   |
| 10-31   | _Reserved_   | (Unused)                               | -                  |

- term **`EN` (Bit 0)**: Single bit; `1` enables, `0` disables.
- term **`MODE` (Bits 2-3)**: 2-bit field; e.g., `0b00` for one-shot, `0b01` for continuous.
- term **`Reserved`**: Unused bits. Write `0` to these (unless the datasheet says otherwise) and preserve their values on read-modify-write operations.
- term **`OVF_FLAG` (Bit 8)**: Read-only flag set by hardware on overflow, cleared by writing `1` to `OVF_CLR`.
- term **`OVF_CLR` (Bit 9)**: Write-only; writing `1` clears `OVF_FLAG`. Reading often returns an undefined value.

Swift MMIO uses macros like ``MMIO/ReadWrite(bits:as:)``, ``MMIO/ReadOnly(bits:as:)``, ``MMIO/WriteOnly(bits:as:)``, and ``MMIO/Reserved(bits:as:)`` within a ``MMIO/Register`` struct to define these fields with type-safe, symbolic names.

### Memory address spaces

Microcontrollers have a memory map that specifies which address ranges correspond to RAM, flash memory (for program code), and peripheral registers. When you instantiate a peripheral block in Swift MMIO (e.g., `MyPeripheral(unsafeAddress: 0x40010000)`), you are asserting that a hardware unit is located at a specific base address in memory. All subsequent register and field accesses within `MyPeripheral` are calculated relative to this base address.

> Important: Use correct base addresses from official documentation. Incorrect addresses can lead to accessing wrong peripherals, hardware faults, data corruption, or system crashes.

Use `SVD2Swift` (part of Swift MMIO) to generate Swift MMIO definitions automatically from CMSIS-SVD files when possible.
