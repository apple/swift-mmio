# Registers

Define and interact with individual hardware registers in a type-safe manner.

## Overview

With memory-mapped I/O (MMIO), you control hardware peripherals by reading from and writing to specific memory addresses. These addresses don't point to regular RAM; instead, they map to **hardware registers**. Each register is a small storage unit, typically 8, 16, 32, or 64 bits wide, that directly influences or reflects the state of a hardware component.

Registers are the fundamental building blocks for controlling peripherals like timers, serial ports, or sensors. For example, writing a specific bit pattern to a control register might enable a timer, while reading from a status register might tell you if a data transmission is complete.

Swift MMIO provides a declarative approach to defining and interacting with these registers. Instead of manual bit manipulation, you use Swift macros to create type-safe and readable hardware interfaces.

> Note: While registers are typically grouped into larger structures called register blocks, this article focuses on defining and understanding individual registers. For information on register blocks, see <doc:Register-Blocks>.

### Defining Registers

The first step in working with a hardware register is to define its basic characteristic: its size. Swift MMIO uses the ``MMIO/Register(bitWidth:)`` macro, applied to a Swift `struct`, to declare a new register type with the specified bit width.

Let's start with a simple status register for a device. According to its datasheet, this register is 32 bits wide:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    // Bit-field definitions will go here
}
```

Even without defining any bit fields, this bare register definition is already usable. To interact with it, first create an instance by providing the memory address where the register is located:

```swift
// Create an instance of DeviceStatus at memory address 0x40000000
let status = DeviceStatus(unsafeAddress: 0x40000000)
```

> Note: The `unsafeAddress` parameter specifies the physical memory location of this register in your hardware's memory map. This address typically comes from your microcontroller's datasheet.

Once you have a register instance, you can read its current value from hardware:

```swift
let readValue = status.read()
if readValue.storage != 0 {
    print("Register contains non-zero value: \(readValue.storage)")
}
```

This performs a read with side effects on the actual hardware. Since our register definition doesn't have any bit fields yet, all you can access is the `.storage` property, which contains the raw bit pattern read from hardware. The type of `storage` is an unsigned integer that matches the bit width specified in the `@Register` macro—in this case, `UInt32` for our 32-bit register.

Without prior knowledge of what the bits mean, you can't do much with this raw value except treat it as a whole.

The next example shows how you can write a value back to the register:

```swift
// Create a raw value to write
let writeValue = DeviceStatus.Write(0b1)
status.write(writeValue)
```

Swift MMIO provides a more convenient closure-based API for writing to registers. This API creates a zeroed write view and lets you modify it within a closure before it writes it to the hardware:

```swift
status.write { writeValue in
    writeValue.storage = 0b1
}
```

A common pattern is to read the current value, modify it, and write it back. This is useful to change some bits while preserving others:

```swift
var value = status.read()
value.storage += 1
status.write(value)
```

This pattern is so common that Swift MMIO provides a dedicated `modify` method. The method reads the current value from hardware, passes it to your closure for modification, then writes the modified value back to hardware:

```swift
status.modify { value in
    value.storage += 1
}
```

While working with bare registers is possible, defining bit fields makes your code much more expressive and safer, as you'll see next.

### Adding Bit Fields

Most hardware registers aren't just simple storage units — they contain multiple functional segments called **bit fields**. Each bit field represents a specific feature or setting within the register. For example, a single 32-bit control register might contain an enable bit, a mode selection field, and status flags, all packed together to efficiently use the available bits.

Let's enhance our `DeviceStatus` register by adding a bit field. According to our hypothetical device's datasheet, bit 1 controls whether interrupts are enabled:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 1..<2)
    var interruptEnable: INTERRUPT_ENABLE
}
```

Here, the example defines a single bit field named `interruptEnable` that occupies bit 1 of the register. The `@ReadWrite` macro indicates that this bit can be both read from and written. The `bits: 1..<2` parameter specifies that this field uses only bit 1.

The type `INTERRUPT_ENABLE` is automatically generated by the Swift MMIO macro system. It contains metadata about the bit field, including its position and width. By convention, these type names should match the field names in the hardware's datasheet; however Swift MMIO does not actually enforce this.

When you read a register with bit fields, Swift MMIO provides a `.raw` view that gives you access to the raw integer values of each field. This view handles all the necessary masking and shifting to extract the correct bits for each field:

```swift
// Create our register instance
let status = DeviceStatus(unsafeAddress: 0x40000000)

// Read the current value
let value = status.read()

// Check if interrupts are enabled
if value.raw.interruptEnable == 1 {
    print("Interrupts are enabled")
} else {
    print("Interrupts are disabled")
}
```

Notice how you access the bit field through the `.raw` property. This gives you access to the raw integer value of the field (0 or 1 in this case).

> Note: The type of `value.raw.interruptEnable` matches the type of `value.storage` — in this case, `UInt32` for our 32-bit register. This consistency makes it easier to work with the raw values when required.

For example, you could use the modify operation and the `.raw.interruptEnable` field to easily enable interrupts on the device while preserving all other bits:

```swift
// Enable interrupts while preserving all other bits
status.modify { value in
    value.raw.interruptEnable = 1
}
```

The raw field accessors like `raw.interruptEnable` are bounds-checked at runtime. If you attempt to write a value that's too large for the field (for example, writing 2 to a 1-bit field), Swift traps with a runtime error. This prevents accidentally modifying other bits in the register and helps catch potential bugs early.

For advanced users who need to perform C-style bit manipulation (though this is generally not recommended), Swift MMIO provides access to the bit masks and offsets as properties available on the generated field type, `INTERRUPT_ENABLE` in this example:

```swift
let value = status.read()
let enabled = (value.storage & DeviceStatus.INTERRUPT_ENABLE.bitMask) >> DeviceStatus.INTERRUPT_ENABLE.bitOffset
if enabled == 1 {
    print("Interrupts are enabled")
} else {
    print("Interrupts are disabled")
}
```

> Important: Unlike the `.raw` accessors, this manual bit manipulation approach is not bounds-checked and therefore less safe. It's provided primarily for compatibility with existing code or for specific optimization requirements where the safety checks might be too costly.

### Adding more fields

The following example creates a more complete register definition with multiple functional fields:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 0..<1)
    var powerEnabled: POWER_ENABLED
    
    @ReadWrite(bits: 1..<2)
    var interruptEnable: INTERRUPT_ENABLE
    
    @ReadWrite(bits: 4..<8)
    var deviceMode: DEVICE_MODE
}
```

The example added a 1-bit `powerEnabled` field at bit 0 and a 4-bit `deviceMode` field at bits 4-7. Now you can interact with all three functional fields:

```swift
// Update status fields
status.modify { value in
    // print the current mode:
    print("Device mode: \(value.raw.deviceMode)")
    // Update the state
    value.raw.powerEnabled = 1       // Power on
    value.raw.interruptEnable = 1    // Enable interrupts
    value.raw.deviceMode = 0b0011    // Set mode to 3
}
```

### Type Projections

Working with raw integer values through the `.raw` property is functional but not ideal. For instance, using `1` and `0` for a power state isn't as clear as using `true` and `false`. Similarly, using numeric constants like `0b0011` for a device mode isn't as expressive as using named values like `.normal` or `.highPerformance`.

Swift MMIO solves this with **type projections**, which map bit field values to more meaningful Swift types. You can project a bit field to any type that conforms to the ``MMIO/BitFieldProjectable`` protocol.

Let's start with a simple example, projecting our 1-bit fields to `Bool`. By adding `as: Bool.self` to our single-bit fields, you can work with them using Swift's native `Bool` type instead of raw integers:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var powerEnabled: POWER_ENABLED
    
    @ReadWrite(bits: 1..<2, as: Bool.self)
    var interruptEnable: INTERRUPT_ENABLE
    
    @ReadWrite(bits: 4..<8)
    var deviceMode: DEVICE_MODE
}
```

With type projections, you can access fields directly without using the `.raw` view:

```swift
// Read the current register state
let value = status.read()

// Check power status using Bool
if value.powerEnabled {
    print("Device is powered on")
} else {
    print("Device is powered off")
}

// Check interrupt enable status using Bool
if value.interruptEnable {
    print("Interrupts are enabled")
} else {
    print("Interrupts are disabled")
}
```

You can also write to these fields using `Bool` values:

```swift
// Set fields using Bool values
status.write { value in
    value.powerEnabled = true      // Power on
    value.interruptEnable = true   // Enable interrupts
}
```

Swift MMIO provides built-in support for projecting bit fields to `Bool` and fixed-width integer types like `UInt8`, `Int16`, and so on. For more complex bit fields, you can define custom types that conform to ``MMIO/BitFieldProjectable``. For detailed instructions on creating custom projections, see <doc:Custom-BitFieldProjectable>.

For multi-bit fields like our `deviceMode`, use a custom enum that gives meaningful names to the different possible values. For example, you can define a `DeviceMode` enum for a 2-bit mode field:

```swift
import MMIO

// Define an enum to represent the device's operating modes
enum DeviceMode: UInt8, BitFieldProjectable {
    // This is a 2-bit field that can represent 4 different modes
    static let bitWidth = 2
    
    case off     = 0b00  // Device powered down
    case low     = 0b01  // Low-power mode
    case normal  = 0b10  // Normal operation
    case high    = 0b11  // High-performance mode
}
```

This `DeviceMode` enum provides meaningful names for each possible value of a 2-bit field. The `BitFieldProjectable` conformance allows Swift MMIO to convert between the raw bit pattern in the register and our strongly-typed enum.

Now you can update your register definition to use this enum for the mode field:

```swift
@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var powerEnabled: POWER_ENABLED
    
    @ReadWrite(bits: 1..<2, as: Bool.self)
    var interruptEnable: INTERRUPT_ENABLE
    
    @ReadWrite(bits: 2..<4, as: DeviceMode.self)
    var deviceMode: DEVICE_MODE
}
```

With this projection in place, you can work with the device mode using the enum's cases:

```swift
// Read the current register state
let value = status.read()

// Check the current device mode using the enum
switch value.deviceMode {
case .off:
    print("Device is off")
case .low:
    print("Device is in low power mode")
case .normal:
    print("Device is in normal mode")
case .high:
    print("Device is in high performance mode")
}

// Set the device mode using the enum
status.modify { value in
    value.deviceMode = .normal
}
```

This makes your code more expressive and less error-prone. Instead of remembering that `0b10` means "normal mode," you can use the descriptive enum case `.normal`.

> Note: Even when you add a type projection, the `.raw` API remains available if you need direct access to the underlying bits. However, the typed API should be preferred for most use cases as it provides better type safety and readability.

### Access Permissions

Hardware registers often have fields with different access permissions. Some bits can only be read (status flags set by hardware), some can only be written (command triggers), and some can be both read and written (configuration settings). Swift MMIO provides macros to model these different access types.

#### Symmetric vs. Asymmetric Registers

Registers can be categorized based on their field access patterns:

- **Symmetric registers** contain only `@ReadWrite` and `@Reserved` fields. You can read and write to all functional fields, making the API for reading and writing consistent.

- **Asymmetric registers** contain `@ReadOnly` and/or `@WriteOnly` fields alongside other types. Different fields are available on different views (Read vs. Write), that leads to a more complex API.

When you call `status.read()`, Swift MMIO returns a `DeviceStatus.Read` view of the register. Similarly, when you call `status.write()`, you're working with a `DeviceStatus.Write` view. For symmetric registers, these views are identical — Swift MMIO uses type aliases to make `Read = ReadWrite` and `Write = ReadWrite`. This is why, in our earlier examples, you could access all fields on both read and write views.

The following example expands the `DeviceStatus` register to include fields with different access permissions:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var powerEnabled: POWER_ENABLED
    
    @ReadWrite(bits: 1..<2, as: Bool.self)
    var interruptEnable: INTERRUPT_ENABLE
    
    @ReadOnly(bits: 2..<3, as: Bool.self)
    var busy: BUSY
    
    @WriteOnly(bits: 3..<4, as: Bool.self)
    var reset: RESET
    
    @ReadWrite(bits: 4..<6, as: DeviceMode.self)
    var deviceMode: DEVICE_MODE
    
    @Reserved(bits: 6...)
    var _reserved: RESERVED
}
```

The `DeviceStatus` register now contains a mix of field types:
- `powerEnabled` and `interruptEnable` are configuration bits that you can be both read and write.
- `busy` is a status bit that can only be read (the hardware sets this bit)
- `reset` is a command bit that can only be written (writing `true` triggers a reset)
- `deviceMode` is a configuration field that can be both read and written
- `_reserved` marks the remaining bits as reserved

This makes `DeviceStatus` an asymmetric register, with different fields available on different views.

#### Field Availability on Different Views

When working with asymmetric registers, different fields are available on different views:

- **Read view**: Contains `@ReadWrite` and `@ReadOnly` fields
- **Write view**: Contains `@ReadWrite` and `@WriteOnly` fields

Swift MMIO enforces these access restrictions at compile time:

```swift
let status = DeviceStatus(unsafeAddress: 0x40000000)

// Reading the register
let readValue = status.read()
let isEnabled = readValue.powerEnabled // OK - ReadWrite field
let isBusy = readValue.busy            // OK - ReadOnly field
// readValue.reset                     // error: can't read WriteOnly field

// Writing to the register
status.write { writeValue in
    writeValue.powerEnabled = true    // OK - ReadWrite field
    writeValue.reset = true           // OK - WriteOnly field
    // writeValue.busy = false        // error: can't write ReadOnly field
}
```

#### Two-Parameter Form of `modify`

For symmetric registers, use the single-parameter form of `modify`:

```swift
status.modify { value in
    value.powerEnabled = true
    value.interruptEnable = true
}
```

For asymmetric registers, use the two-parameter version of `modify` that provides both the current read value and a write value to modify:

```swift
status.modify { readValue, writeValue in
    // Use readValue to check current state
    if readValue.busy {
        print("Device is busy, not changing settings")
        return
    }
    
    // Use writeValue to update settings
    writeValue.powerEnabled = true
    writeValue.deviceMode = .normal
    
    // Trigger a reset if needed
    if readValue.deviceMode == .high {
        writeValue.reset = true
    }
}
```

This form is necessary because some fields are only available on the read view, while others are only available on the write view.

#### Special Hardware Behaviors

Some register fields have special hardware behaviors that aren't directly captured by the access type. Swift MMIO provides the general read and write capabilities, but you need to handle these special behaviors in your application logic.

The following examples illustrate some common patterns, but this is not a comprehensive list:

**Write-1-to-clear flags:**
These are bits that you clear by writing a 1 to them, while writing 0 has no effect. They're often used for interrupt flags:

```swift
@Register(bitWidth: 32)
struct InterruptStatus {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var overflowFlag: OVERFLOW_FLAG
}

// To check and clear the overflow flag:
let intStatus = InterruptStatus(unsafeAddress: 0x40000008)
if intStatus.read().overflowFlag {
    print("Overflow detected!")

    // Clear the flag by writing 1 to it
    intStatus.write { writeValue in
        writeValue.overflowFlag = true
    }
}
```

**Read-to-clear behavior:**
Some flags are automatically cleared when read. You need to be careful with these, as each read operation affects the hardware state:

```swift
@Register(bitWidth: 32)
struct FIFOStatus {
    @ReadOnly(bits: 0..<1, as: Bool.self)
    var dataAvailable: DATA_AVAILABLE
}

// Reading this flag will clear it in hardware
let status = FIFOStatus(unsafeAddress: 0x4000000C).read()
if status.dataAvailable {
    print("Data is available, flag now cleared")
    // Process the data...
}
```

**Toggle bits:**
Some bits toggle their state when written with a 1:

```swift
@Register(bitWidth: 32)
struct LEDControl {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var ledToggle: LED_TOGGLE
}

// Toggle the LED state
LEDControl(unsafeAddress: 0x40000010).write { writeValue in
    writeValue.ledToggle = true
}
```

You must handle these special behaviors in your application code based on the hardware's requirements.

### Discontiguous Bitfields

Some hardware registers use non-adjacent bits to represent a single logical value. Swift MMIO supports this through discontiguous bit fields, which you define by providing multiple bit ranges to the field macros.

> Note: Use discontiguous bit fields only when necessary to match hardware requirements. They add complexity and can make your code harder to understand.

For example, suppose our device status register's mode field is split across two non-adjacent bit ranges:

```swift
import MMIO

@Register(bitWidth: 32)
struct DeviceStatus {
    @ReadWrite(bits: 2..<4, 6..<8)
    var deviceMode: DEVICE_MODE

    // ...
}
```

The order of ranges is important:
- The first range (2..<4) provides the least significant bits
- The second range (6..<8) provides the more significant bits

When you read this field, Swift MMIO combines the bits from both ranges into a single logical value:

```swift
let status = DeviceStatus(unsafeAddress: 0x40000000)

// If bits 2-3 contain 0b01 and bits 6-7 contain 0b10,
// the logical value of deviceMode will be 0b1001 (9)
let value = status.read().raw.deviceMode
```

When writing, Swift MMIO splits the logical value across the physical bit ranges:

```swift
status.write { view in
    // Writing 0b1101 (13) will set:
    // - bits 2-3 to 0b01
    // - bits 6-7 to 0b11
    view.raw.deviceMode = 0b1101
}
```

> Note: Discontiguous bit fields work with type projections just like regular bit fields. The projected type's `bitWidth` must match the total logical width of the discontiguous field.

Do not use discontiguous bit fields for reserved bits. Instead, define separate `@Reserved` fields for each contiguous range of reserved bits.

## Topics

- ``MMIO/Register``
- ``MMIO/Register(bitWidth:)``

### Bit Field Macros

- ``MMIO/ReadWrite(bits:as:)``
- ``MMIO/ReadOnly(bits:as:)``
- ``MMIO/WriteOnly(bits:as:)``
- ``MMIO/Reserved(bits:as:)``

### Register Implementation Details

- ``MMIO/RegisterProtocol``
- ``MMIO/RegisterValue``
- ``MMIO/RegisterValueRaw``
- ``MMIO/RegisterValueRead``
- ``MMIO/RegisterValueWrite``

### Bit Field Implementation Details

- ``MMIO/BitField``
- ``MMIO/ContiguousBitField``
- ``MMIO/DiscontiguousBitField``
