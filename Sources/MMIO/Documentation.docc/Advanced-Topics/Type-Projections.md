# Using Type Projections for Bit Fields

Improve type safety and clarity by mapping bit field values to meaningful Swift types.

## Overview

Bit fields in hardware registers fundamentally represent segments of integers. However, directly manipulating these raw integer values (accessed via the `.raw` property on a register's `Read` or `Write` view) can be error-prone and can obscure the intended meaning of the code. For instance, a single bit might represent an on/off state, which is more naturally expressed as a `Bool` in Swift. Similarly, a 2-bit field might represent one of four specific operational modes, ideally represented by an `enum`.

Swift MMIO's **type projection** allows associating a more expressive Swift type with a bit field using the `as: SomeType.Type` parameter in bit field macros (e.g., ``MMIO/ReadWrite(bits:as:)``). `SomeType` must conform to ``MMIO/BitFieldProjectable``.

## The `BitFieldProjectable` Protocol

A type conforming to ``MMIO/BitFieldProjectable`` defines conversions between its representation and the bit field's raw integer value (masked and shifted).

Conformance requires:
- **`static var bitWidth: Int`**: The number of bits the projected type occupies. This **must** match the physical bit field's width.
- **`init<Storage: FixedWidthInteger & UnsignedInteger>(storage: Storage)`**: Creates an instance from an unsigned integer read from the bit field.
  - The `storage` value is **guaranteed by Swift MMIO to be masked** to `Self.bitWidth`.
  - If the type cannot represent all valid bit patterns within `Self.bitWidth` (e.g., an enum with `bitWidth = 2` defining cases for `0b00`, `0b01` but not `0b10`, `0b11`), this initializer must handle unrepresented patterns (e.g., trap, default/error case).
- **`func storage<Storage: FixedWidthInteger & UnsignedInteger>(_: Storage.Type) -> Storage`**: Converts an instance back to an unsigned integer for writing to the bit field.
  - The returned value **must only use bits up to `Self.bitWidth`**. Values `(1 << Self.bitWidth)` or greater will cause a runtime trap when written.

Swift MMIO provides ``MMIO/BitFieldProjectable`` conformance for `Bool` and standard `FixedWidthInteger` types (e.g., `UInt8`, `Int8`). For signed types, conformance handles two's complement interpretation within the specified `bitWidth`.

## Projecting to `Bool`

A common use case for type projection is representing single-bit flags or settings as `Bool` values.

```swift
import MMIO

@Register(bitWidth: 32)
struct StatusRegister {
    @ReadOnly(bits: 0..<1, as: Bool.self)
    var isReady: IS_READY

    @ReadWrite(bits: 1..<2, as: Bool.self)
    var enableFeature: ENABLE_FEATURE
}

let statusReg = Register<StatusRegister>(unsafeAddress: 0x40001000)

// Reading a Bool-projected field:
if statusReg.read().isReady {
    print("Device is ready.")
}

// Modifying a Bool-projected field:
statusReg.modify { view in
    view.enableFeature = true
}
```
Without `as: Bool.self`, fields would be accessed via `.raw` (e.g., `statusReg.read().raw.isReady`), yielding a raw integer (0 or 1).

## Projecting to Custom Enumerations

For bit fields representing a set of distinct, named states, `RawRepresentable` enumerations are highly effective.

```swift
import MMIO

enum ADCMode: UInt8, BitFieldProjectable {
    // This enum is a 2-bit field.
    static let bitWidth: Int = 2

    case singleConversion     = 0b00
    case continuousConversion = 0b01
    case scanChannelsOnce     = 0b10
    case scanChannelsCont     = 0b11
    // A custom `init(storage:)` would be needed if hardware could produce
    // a 2-bit pattern not covered here and a trap is not desired.
}

@Register(bitWidth: 32)
struct ADCControl {
    // Bits 4-5 represent the ADC mode, projected to ADCMode.    
    @ReadWrite(bits: 4..<6, as: ADCMode.self)
    var conversionMode: CONVERSION_MODE
}

let adcCtrl = Register<ADCControl>(unsafeAddress: 0x40002000)

// Set the ADC mode using the enum:
adcCtrl.modify { view in
    view.conversionMode = .continuousConversion
}

// Read the ADC mode:
let currentMode = adcCtrl.read().conversionMode
switch currentMode {
case .singleConversion:
    print("ADC in single conversion mode.")
case .continuousConversion:
    print("ADC in continuous conversion mode.")
default:
    print("ADC in another mode: \(currentMode.rawValue)")
}
```

**Simplified Conformance for `RawRepresentable` Types:**
If your custom type (like an `enum`) conforms to `RawRepresentable` and its `RawValue` is a `FixedWidthInteger & UnsignedInteger`, Swift MMIO provides a default implementation for `init(storage:)` and `storage(_:)` requirements of ``MMIO/BitFieldProjectable``. You only need to explicitly provide `static var bitWidth`.
- The default `init(storage:)` will trap if the `storage` value (already masked by MMIO to `Self.bitWidth`) does not correspond to a valid `rawValue` of the enum.
- The default `storage(_:)` will use the enum case's `rawValue`.

## Projecting to Custom Structs

A custom `struct` can be used for more complex bit field representations.

```swift
import MMIO

// A 3-bit field where bits 0-1 are 'value' and bit 2 is 'valid'.
struct FieldWithOptions: BitFieldProjectable {
    static let bitWidth: Int = 3

    var value: UInt8
    var isValid: Bool

    init(value: UInt8, isValid: Bool) {
      precondition(value < 4, "Value must be 2 bits (0-3).")
      self.value = value
      self.isValid = isValid
    }

    init<Storage: FixedWidthInteger & UnsignedInteger>(storage: Storage) {
        // 'storage' is pre-masked by MMIO to Self.bitWidth.
        precondition(Storage.bitWidth >= Self.bitWidth)
        self.value = UInt8(storage & 0b011) // Extract bits 0-1
        self.isValid = (storage & 0b100) != 0 // Extract bit 2
    }

    func storage<Storage: FixedWidthInteger & UnsignedInteger>(_: Storage.Type) -> Storage {
        let valueBits = self.value & 0b011
        let validBit = self.isValid ? 0b100 : 0b000
        return Storage(validBit | valueBits)
    }
}

@Register(bitWidth: 16)
struct ConfigurationRegister {
    // Field is 3 bits wide, matching FieldWithOptions.bitWidth
    @ReadWrite(bits: 5..<8, as: FieldWithOptions.self)
    var settingAlpha: SETTING_ALPHA
}

// Example usage:
let configReg = Register<ConfigurationRegister>(unsafeAddress: 0x40003000)
configReg.modify {
    $0.settingAlpha = FieldWithOptions(value: 0b10, isValid: true)
}
let currentSetting = configReg.read().settingAlpha
print("""
    Setting Alpha:
      value=\(currentSetting.value)
      isValid=\(currentSetting.isValid)
    """)
```

### Important Considerations for Type Projections:

- **Bit Width Match is Critical:** The `static var bitWidth` in your ``MMIO/BitFieldProjectable`` type **must** exactly match the width of the physical bit field in the register macro (e.g., `bits: 4..<6` is 2 bits wide). Mismatches cause a runtime trap on access. This indicates a bug in your register or field definition.

- **Valid Raw Values and Enum Cases:**
    - **Enum `init(storage:)`:** For enums using default `RawRepresentable` conformance, the initializer traps if a hardware `storage` value (masked by MMIO to `Self.bitWidth`) isn't a valid `rawValue`. For hardware patterns not covered by enum cases, provide a custom `init(storage:)` or project to a `struct` that models these states.
    - **Enum `rawValue` Size:** Ensure all enum `rawValue`s fit within `BitFieldProjectable.bitWidth`. A `rawValue` requiring more bits than `Self.bitWidth` is an error. Its `storage` conversion will exceed `(1 << Self.bitWidth)`, causing a runtime trap on write.
