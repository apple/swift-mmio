# Understanding Memory-Mapped I/O

Learn how you can communicate with hardware devices.

## Overview

> FIXME: "In an MMIO system" weird

Memory-Mapped I/O (MMIO) is a common technique in computer architecture that enables the Central Processing Unit (CPU) to interact with hardware peripherals. In an MMIO system, the control interfaces, status indicators, and data buffers of hardware devices—such as timers, serial communication interfaces (UARTs), General-Purpose Input/Output (GPIO) controllers, and Serial Peripheral Interface (SPI) controllers—are assigned specific addresses within the CPU's main memory address space.

This means the CPU can control and monitor hardware by reading from or writing to these special memory addresses, using the same load and store instructions it employs for accessing regular Random Access Memory (RAM). This approach contrasts with systems that use dedicated I/O instructions (often called Port-Mapped I/O).

For instance, if a GPIO peripheral has a "Port Data Output Register" at memory address `0x400FF000`, the CPU could set the third pin of this port high (assuming pin 3 corresponds to bit 3 of the register) by writing the value `0x00000008` (which is binary `...00001000`) to that address.

> FIXME: remove?

Swift MMIO provides a safe, structured, and Swift-idiomatic way to perform these memory accesses.

## Registers

In the context of MMIO, a **register** is a small, fixed-size storage location within a hardware peripheral. Each register serves a specific purpose:

- **Control Registers:** Configure the behavior of the peripheral. Examples include enabling or disabling features, setting operational modes, or selecting clock sources.
- **Status Registers:** Reflect the current state of the peripheral, such as whether an operation is complete, an error has occurred, or data is ready. These are often read-only, or specific bits might be cleared automatically upon reading (a "read-to-clear" mechanism).
- **Data Registers:** Transfer data to or from the peripheral. For example, writing a byte to a UART transmit data register sends it over the serial line, while reading an Analog-to-Digital Converter (ADC) result register retrieves the latest conversion value.

Registers are typically 8, 16, 32, or 64 bits wide, aligning with the processor's data bus width or common data sizes. The precise address, layout, and behavior of each register for a microcontroller are detailed in its **reference manual** or **datasheet**. This document is the authoritative source for understanding a peripheral's register structure. The datasheet also specifies critical details like the reset value of each register (its state after a system reset).

Swift MMIO uses the ``MMIO/Register`` macro to define the structure and properties of individual registers based on this hardware documentation.

> FIXME: registers are always read/written a single continguous unit and individual fields within them cannot be mutated independently of the others. THIS isn't precise enough phrasing and is confusing.

## Bit fields

A single hardware register is often subdivided into smaller **bit fields**, each controlling or representing distinct information.

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
- term **`Reserved`**: Unused bits. Software typically writes `0` (unless specified otherwise) and preserves their values on read-modify-write.
- term **`OVF_FLAG` (Bit 8)**: Read-only flag set by hardware on overflow, cleared by writing `1` to `OVF_CLR`.
- term **`OVF_CLR` (Bit 9)**: Write-only; writing `1` clears `OVF_FLAG`. Reading often returns an undefined value.

Swift MMIO uses macros like ``MMIO/ReadWrite(bits:as:)``, ``MMIO/ReadOnly(bits:as:)``, ``MMIO/WriteOnly(bits:as:)``, and ``MMIO/Reserved(bits:as:)`` within a ``MMIO/Register`` struct to define these fields, enabling symbolic, type-safe manipulation and <doc:Type-Projections>.

Understanding the register map and bit fields for your microcontroller is crucial. Tools like `SVD2Swift` (part of Swift MMIO) can automate generating Swift MMIO definitions from CMSIS-SVD files.

## Memory address spaces

Microcontrollers have a memory map that specifies which address ranges correspond to RAM, flash memory (for program code), and peripheral registers. When you instantiate a peripheral block in Swift MMIO (e.g., `MyPeripheral(unsafeAddress: 0x40010000)`), you are asserting that this hardware unit is located at that specific base address in memory. All subsequent register and field accesses within `MyPeripheral` are calculated relative to this base address.

> Important: Use correct base addresses from official documentation. Incorrect addresses can lead to accessing wrong peripherals, hardware faults, data corruption, or system crashes.
