# Understanding Memory-Mapped I/O

Learn how software controls hardware peripherals through registers at memory addresses.

## Overview

With memory-mapped I/O (MMIO), software controls hardware peripherals through ordinary memory reads and writes.

A chip, from a small microcontroller to a large system on a chip (SoC), contains one or more CPUs, memory, and peripherals: hardware units such as timers, general-purpose input/output (GPIO) pins, and serial interfaces such as UART and SPI. Each peripheral has registers at fixed addresses in the CPU's memory space.

To control a peripheral, the CPU reads from and writes to these addresses with the same load and store instructions that access RAM. In Swift, this is similar to reading and writing through a pointer, but the memory at the address is a hardware device, not RAM. Some processors also have port-mapped I/O, which uses separate I/O instructions in place of loads and stores.

For example, suppose bit 3 of a GPIO data output register at address `0x400F_F000` controls pin 3. To set pin 3 high (make the pin output a high voltage), the CPU stores `0x0000_0008`, a value with only bit 3 set, to that address.

You can think of MMIO as the ABI of the hardware, and the registers of each peripheral as its API. The ABI is the low-level convention that all access uses: loads and stores to addresses. The API is the specific set of registers and bit fields that a peripheral makes available, which its datasheet documents.

### Registers

A register is a small, fixed-size storage location in a peripheral. Registers usually have one of these purposes:

- term **Control registers**: Configure the behavior of the peripheral. Examples include enabling or disabling features, setting operational modes, or selecting clock sources.
- term **Status registers**: Reflect the current state of the peripheral, such as whether an operation is complete, an error has occurred, or data is ready. The datasheet specifies whether you can write to a status register, and whether a read changes its value. For example, some status bits clear when you read them.
- term **Data registers**: Transfer data to or from the peripheral. For example, writing a byte to a UART transmit data register sends it over the serial line, while reading an analog-to-digital converter (ADC) result register retrieves the latest conversion value.

Swift MMIO supports registers that are 8, 16, or 32 bits wide, and 64 bits wide on 64-bit targets. The chip vendor describes the address, layout, behavior, and reset value (the value after a system reset) of each register in the chip's datasheet or reference manual.

In Swift MMIO, you define each register from the datasheet with the ``MMIO/Register(bitWidth:)`` macro.

### Bit fields

Hardware registers are usually divided into smaller bit fields, where each field controls or represents a specific piece of information.

For example, the datasheet of a timer might describe its 32-bit control register, `TIMER_CTRL`, like this:

| Bits    | Name         | Description         | Access             |
|:--------|:-------------|:------------------- |:-------------------|
| 0       | `EN`         | Timer enable        | Read/Write         |
| 1       | `INT_EN`     | Interrupt enable    | Read/Write         |
| 2-3     | `MODE`       | Timer mode select   | Read/Write         |
| 4-7     | _Reserved_   | (Unused)            | -                  |
| 8       | `OVF_FLAG`   | Overflow flag       | Read-Only          |
| 9       | `OVF_CLR`    | Clear overflow flag | Write-Only         |
| 10-31   | _Reserved_   | (Unused)            | -                  |

- term **`EN` (Bit 0)**: Single bit; `1` enables, `0` disables.
- term **`INT_EN` (Bit 1)**: When `1`, the timer can send an interrupt: a signal that makes the CPU pause its current code and run a handler function.
- term **`MODE` (Bits 2-3)**: 2-bit field. For example, `0b00` selects one-shot mode and `0b01` selects continuous mode.
- term **`Reserved`**: Unused bits. The datasheet specifies which value to write to these bits.
- term **`OVF_FLAG` (Bit 8)**: Read-only flag set by hardware on overflow, cleared by writing `1` to `OVF_CLR`.
- term **`OVF_CLR` (Bit 9)**: Write-only; writing `1` clears `OVF_FLAG`. The datasheet specifies the value that you get if you read it.

In Swift MMIO, write this table as a struct with the ``MMIO/Register(bitWidth:)`` macro. Each row of the table becomes one property with a bit field macro:

```swift
import MMIO

@Register(bitWidth: 32)
struct TimerCtrl {
    @ReadWrite(bits: 0, as: Bool.self)
    var en: EN

    @ReadWrite(bits: 1, as: Bool.self)
    var intEn: INT_EN

    @ReadWrite(bits: 2..<4)
    var mode: MODE

    @Reserved(bits: 4..<8)
    var reserved0: RESERVED0

    @ReadOnly(bits: 8, as: Bool.self)
    var ovfFlag: OVF_FLAG

    @WriteOnly(bits: 9, as: Bool.self)
    var ovfClr: OVF_CLR

    @Reserved(bits: 10...)
    var reserved1: RESERVED1
}
```

The columns of the table map to the code as follows:

- term **Bits**: The `bits` parameter. For a single bit, give the bit index, such as `0`. For more than one bit, give a range: bits 2-3 become `2..<4`, and bits 10-31 become `10...`.
- term **Name**: The name of the field type, such as `EN`, and the property name in lower camel case, such as `en`. The macros generate the field types.
- term **Access**: The macro. Use ``MMIO/ReadWrite(bits:as:)``, ``MMIO/ReadOnly(bits:as:)``, ``MMIO/WriteOnly(bits:as:)``, or ``MMIO/Reserved(bits:as:)``.

The optional `as:` parameter gives the field a Swift type. Here, the 1-bit fields are `Bool` values. For more information, see <doc:Registers>.

### Registers are read and written as a whole

Swift MMIO reads a register with one load of the register's full width, and writes it with one store of the full width. A bit field is a part of that value, so Swift MMIO doesn't access a field by itself.

To change one field, your code must:

1. Read the full register.
2. Change the bits of the field in that value.
3. Write the full register back.

This sequence is a **read-modify-write**. The ``MMIO/Register/modify(_:)-((Value.Read,Value.Write)->(T))`` method performs this sequence with one read and one write. To learn how Swift MMIO performs each access, see <doc:Volatile-Access>.

Because a write stores every bit of the register, the value that you write for the other fields also matters. The datasheet tells you which value is correct for each field.

The `modify` method starts from the value that it read. It writes back the read value of every bit that your closure doesn't change, including the bits of write-only and reserved fields. The ``MMIO/Register/write(_:)->_`` method starts from a value in which all bits are zero.

### Memory maps and base addresses

A chip has a memory map that specifies which address ranges correspond to memory, such as RAM and flash, and which correspond to peripheral registers. Each peripheral starts at a **base address**, and each of its registers is at a fixed **offset** from that base address. The datasheet gives both values.

For example, suppose a timer peripheral has its base address at `0x4000_1000`, and its control register is at offset `0x08`. The address of the control register is the sum of the two:

```
  0x4000_1000   base address of the timer
+ 0x0000_0008   offset of TIMER_CTRL
= 0x4000_1008   address of TIMER_CTRL
```

In Swift MMIO, you give the offset in a ``MMIO/RegisterBlock()`` struct, and the base address when you create an instance:

```swift
@RegisterBlock
struct Timer {
    @RegisterBlock(offset: 0x08)
    var ctrl: Register<TimerCtrl>
}

let timer = Timer(unsafeAddress: 0x4000_1000)

// timer.ctrl accesses the register at address 0x4000_1008
let value = timer.ctrl.read()
```

Swift MMIO calculates the address of each register from the base address and the offset. For more information, see <doc:Register-Blocks>.

> Important: Get each base address from the datasheet. If an address is wrong, your code accesses the wrong memory, which can cause hardware faults, data corruption, or crashes. See <doc:Safety-Considerations>.

On a system with a memory management unit (MMU), such as an application processor that runs an operating system, use the virtual address that your operating system or page tables map to the peripheral, not the physical address from the datasheet.

If your hardware vendor supplies a CMSIS-SVD file, [SVD2Swift](https://swiftpackageindex.com/apple/swift-mmio/main/documentation/svd2swift) can generate these definitions for you.

To learn how Swift MMIO reads and writes registers, and why it can't use plain memory accesses, see <doc:Volatile-Access>.
