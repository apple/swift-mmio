# Getting Started

Define a register, add it to a register block, and read, write, and modify it.

## Overview

This article shows the shortest path from a datasheet to working code. It uses a hypothetical timer peripheral with one control register. For more details about each step, see <doc:Registers> and <doc:Register-Blocks>.

> Note: Before you start, add Swift MMIO to your project. See <doc:Installation>.

### Read the datasheet

Suppose the datasheet for your microcontroller describes a timer peripheral at base address `0x4000_0000`. The timer has a 32-bit control register at offset `0x00`:

| Bits | Name        | Description              | Access     |
|:-----|:------------|:-------------------------|:-----------|
| 0    | `ENABLE`    | Timer enable             | Read/Write |
| 1-3  | `PRESCALER` | Clock prescaler          | Read/Write |


### Define the register

Define the layout of the control register with the ``MMIO/Register(bitWidth:)`` macro. Add a property with a bit field macro for each field:

```swift
import MMIO

@Register(bitWidth: 32)
struct TimerControl {
    @ReadWrite(bits: 0, as: Bool.self)
    var enable: ENABLE

    @ReadWrite(bits: 1..<4)
    var prescaler: PRESCALER
}
```

The `bits` parameter gives the position of each field. A single bit index, such as `0`, is a one-bit field. A range, such as `1..<4`, is a field of more than one bit.

The `as: Bool.self` parameter projects the `enable` field as a `Bool`, so you can use `true` and `false` in place of `1` and `0`. The `prescaler` field has no projection, so you access it as an integer through the `raw` property.

The macros generate the field types, such as `ENABLE` and `PRESCALER`, so you don't define them yourself.

### Add the register to a register block

A peripheral usually has more than one register. Define the peripheral with the ``MMIO/RegisterBlock()`` macro, and give each register its offset from the base address of the peripheral:

```swift
@RegisterBlock
struct Timer {
    @RegisterBlock(offset: 0x00)
    var control: Register<TimerControl>
}
```

To add more registers later, add more properties, each with its own offset.

### Create the peripheral

Create an instance of the peripheral at its base address from the datasheet:

```swift
let timer = Timer(unsafeAddress: 0x4000_0000)
```

The parameter is named `unsafeAddress` because Swift can't verify that the peripheral is at this address. If the address is wrong, your code accesses the wrong memory. See <doc:Safety-Considerations>.

### Read the register

Use ``MMIO/Register/read()`` to read the register from hardware once. Then use the fields of the value:

```swift
let value = timer.control.read()
if value.enable {
    print("Timer is running with prescaler \(value.raw.prescaler)")
}
```

### Write the register

Use `write` to set the full register. The closure starts from a value with all bits set to zero, so every field that you don't set is written as zero:

```swift
timer.control.write { value in
    value.enable = true
    value.raw.prescaler = 2
}
```

### Modify the register

Use `modify` to change some fields and keep the values of the other fields. The method reads the register once, runs your closure, and then writes the register once:

```swift
timer.control.modify { value in
    value.raw.prescaler = 5
}
```

After this call, `enable` keeps the value that it had before.

### Next steps

- <doc:Registers> describes bit fields, access permissions, and type projections in more detail.
- <doc:Register-Blocks> describes nested register blocks and arrays of registers.
- <doc:Custom-BitFieldProjectable> describes how to project a field as your own type, such as an enum.
- If your hardware vendor supplies a CMSIS-SVD file, [SVD2Swift](https://swiftpackageindex.com/apple/swift-mmio/main/documentation/svd2swift) can generate these definitions for you.
