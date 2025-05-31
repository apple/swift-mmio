# Creating BitFieldProjectable Types

Define projections to map hardware bit fields to meaningful Swift types.

## Overview

When working with memory-mapped hardware registers, you're fundamentally manipulating raw bits. However, these bits often represent meaningful concepts: a single bit might indicate an enabled/disabled state, a 2-bit field might represent one of four operating modes, or a multi-bit field might encode a complex configuration.

Swift MMIO provides **type projections** through the ``MMIO/BitFieldProjectable`` protocol, allowing you to map raw bit patterns to semantically meaningful Swift types. While Swift MMIO includes built-in projections for common types like `Bool` and integer types, creating your own custom projections offers several key benefits:

- **Improved type safety**: Replace magic numbers with strongly-typed values
- **Better code readability**: Express hardware states with meaningful names
- **Compile-time validation**: Catch errors at compile time rather than runtime
- **Domain-specific abstractions**: Model hardware concepts using appropriate Swift types

This article guides you through creating custom types that conform to ``MMIO/BitFieldProjectable``, enabling you to represent hardware bit fields in a way that's both safer and more expressive.

### Understanding the BitFieldProjectable protocol

The ``MMIO/BitFieldProjectable`` protocol defines the contract between your custom type and a bit field macro. To create a custom projection, your type must implement three key requirements:

```swift
public protocol BitFieldProjectable {
    static var bitWidth: Int { get }

    init<Storage>(storage: Storage)
    where Storage: FixedWidthInteger & UnsignedInteger

    func storage<Storage>(_: Storage.Type) -> Storage
    where Storage: FixedWidthInteger & UnsignedInteger
}
```

Let's examine each requirement in detail:

#### Bit width

```swift
static var bitWidth: Int { get }
```

This property defines how many bits your type occupies in the hardware register. This value must **exactly match** the width of the physical bit field as defined in your register macro (e.g., `bits: 4..<6` is 2 bits wide).

A mismatch between your type's `bitWidth` and the actual bit field width will cause a runtime trap when accessing the register. This is a safety feature that ensures your type accurately represents the hardware's capabilities.

#### Converting from storage

```swift
init<Storage>(storage: Storage) where Storage: FixedWidthInteger & UnsignedInteger
```

This initializer creates an instance of your type from a raw integer value read from the hardware. When Swift MMIO reads a register, it:

1. Reads the entire register value
2. Extracts the relevant bits for your field (masking and shifting)
3. Passes this extracted value to your initializer

Your initializer must handle all possible bit patterns within `Self.bitWidth`. If your type cannot represent all possible bit patterns (e.g., an enum with fewer cases than possible bit combinations), you must decide how to handle invalid patterns.

#### Converting to storage

```swift
func storage<Storage>(_: Storage.Type) -> Storage where Storage: FixedWidthInteger & UnsignedInteger
```

This method converts your type back to a raw integer value for writing to the hardware. When Swift MMIO writes to a register containing your projected field, it:

1. Calls this method to get the raw bits
2. Places these bits at the correct position in the register value
3. Writes the complete register value to hardware

The returned value must only use bits up to `Self.bitWidth` or will cause a runtime trap when written. The method should accurately represent your type's state in the bit pattern expected by the hardware

### Projecting an enum

Enumerations are ideal for bit fields that represent a fixed set of distinct states or modes. Let's create a custom enum to represent a device's power mode, which is stored in a 2-bit field:

```swift
import MMIO

enum PowerMode: UInt8, BitFieldProjectable {
    // This is a 2-bit field
    static let bitWidth: Int = 2

    case off = 0b00
    case low = 0b01
    case normal = 0b10
    case high = 0b11
}
```

This enum defines four possible power modes, each mapped to a specific 2-bit pattern. The `BitFieldProjectable` conformance comes from:

1. Explicitly defining `static let bitWidth = 2` to match our 2-bit field
2. Conforming to `RawRepresentable` (via `UInt8`)
3. Leveraging Swift MMIO's default implementations for `RawRepresentable` types

For `RawRepresentable` types, Swift MMIO provides default implementations of the required initializer and storage method:

- The default `init(storage:)` will attempt to create an enum case from the raw value, trapping if no matching case exists
- The default `storage(_:)` will use the enum case's `rawValue`

Now let's use this enum in a register definition:

```swift
@Register(bitWidth: 32)
struct PowerControl {
    @ReadWrite(bits: 0..<2, as: PowerMode.self)
    var mode: MODE
}

// Create a register instance
let powerCtrl = Register<PowerControl>(unsafeAddress: 0x40001000)

// Read the current power mode
let currentMode = powerCtrl.read().mode
switch currentMode {
case .off:
    print("Device is powered off")
case .low:
    print("Device is in low power mode")
case .normal:
    print("Device is in normal power mode")
case .high:
    print("Device is in high performance mode")
}

// Set the power mode
powerCtrl.write { view in
    view.mode = .normal
}
```

### Advanced projections

Sometimes hardware registers have more complex requirements than simple one-to-one mappings. You might encounter situations where:

- Only certain bit patterns are valid, with others being reserved or undefined
- Some bits in a field are "don't care" bits that don't affect functionality
- You need to represent a logical grouping of related values

Let's explore a practical example that handles these scenarios. Imagine we have a fan controller with a 2-bit field that represents the fan speed:

- `0bx0` is off (where x is a "don't care" bit)
- `0b01` is low speed
- `0b11` is high speed

This is a common pattern in hardware where not all possible bit combinations are valid or meaningful.

First, we'll define a custom type that implements both `BitFieldProjectable` and `RawRepresentable`:

```swift
struct FanSpeed: BitFieldProjectable, RawRepresentable {
    static let bitWidth = 2

    var rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}
```

This establishes our basic structure - a 2-bit field represented by a `UInt8` raw value. Now, let's add a way to handle pattern matching for "don't care" bits. We'll create a `Pattern` structure that can represent a value and a mask:

```swift
struct FanSpeed: BitFieldProjectable, RawRepresentable {
    // ...

    struct Pattern {
        var rawValue: UInt8
        var mask: UInt8
    }

    static func ~= (pattern: Pattern, value: Self) -> Bool {
        (value.rawValue & pattern.mask) == pattern.rawValue
    }
}
```

The custom `~=` operator enables pattern matching that considers only the bits specified by the mask. This is perfect for "don't care" scenarios where only certain bits matter for a particular state.

Now, let's define our named values and patterns:

```swift
struct FanSpeed: BitFieldProjectable, RawRepresentable {
    // ...

    // Specific values
    static let low = Self(rawValue: 0b01)
    static let high = Self(rawValue: 0b11)

    // Pattern with don't-care bit
    static let off = Pattern(rawValue: 0b00, mask: 0b01)
}
```

Here we've defined two specific named values (`0b01` for low speed and `0b11` for high speed) and a pattern for "off" where only the least significant bit matters (mask `0b01`). This means both `0b00` and `0b10` are considered "off" states.

Finally, let's add a factory method that creates values matching our "off" pattern:

```swift
struct FanSpeed: BitFieldProjectable, RawRepresentable {
    // ... 

    static func off(rawValue: UInt8 = 0b00) -> Self {
        let value = Self(rawValue: rawValue)
        precondition(off ~= value, "Invalid bits set in rawValue")
        return value
    }
}
```

This factory method creates values that match our "off" pattern, with validation to ensure the critical bits are set correctly.

Let's see how we can use this type in practice:

```swift
@Register(bitWidth: 32)
struct FanControl {
    @ReadWrite(bits: 4..<6, as: FanSpeed.self)
    var speed: SPEED
}

let fanControl = Register<FanControl>(unsafeAddress: 0x40003000)

// Reading the register and checking the fan speed
let currentSpeed = fanControl.read().speed

// Pattern matching with specific values
switch currentSpeed {
case .off:
    print("Fan is off")
case .low:
    print("Fan is running at low speed")
case .high:
    print("Fan is running at high speed")
default:
    print("Unexpected fan speed value: \(currentSpeed.rawValue)")
}

// Writing a specific value
fanControl.modify { view in
    view.speed = .low
}

// Writing a pattern-based value
fanControl.modify { view in
    // Using the alternate "off" pattern
    view.speed = .off(rawValue: 0b10)
}
```

This approach gives us tremendous flexibility. We can represent specific named values for common states, while also handling bit patterns with "don't care" bits. The custom pattern matching allows us to check if a value matches a particular pattern, ignoring bits that don't affect functionality.

The real power of this technique becomes apparent when working with hardware that has complex bit field semantics. For example, many hardware peripherals use bit patterns where:
- Some bits are reserved and must be zero
- Some bits are "don't care" bits that can be either 0 or 1
- Some combinations of bits are invalid or represent special modes

With a custom `BitFieldProjectable` type, you can model these relationships explicitly, making your code both safer and more expressive.
