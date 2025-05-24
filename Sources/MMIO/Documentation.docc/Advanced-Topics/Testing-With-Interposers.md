# Testing with Interposers

Verify register interaction logic without actual hardware using interposers.

## Overview

> FIXME: make this more succinct v, just a little wordy

Testing software that directly interacts with hardware registers can be challenging. Traditionally, it often requires:

> FIXME: choose 1/2 and no bulleted list

- The specific target hardware.
- A debugger connection or other means to observe and manipulate hardware state.
- Potentially complex setup procedures to bring the hardware into specific states for testing various scenarios.

This can make unit testing slow, expensive, and difficult to automate, especially for driver logic and peripheral control routines. Ideally, you want to verify the *logic* of how registers are accessed—what values are written, in what sequence, and based on what inputs—independently of the physical hardware.

Swift MMIO addresses this with an **interposer** mechanism.

> FIXME: join these two: ^ v

An interposer is an object that can "intercept" or "interpose" on memory load and store operations that would normally target MMIO registers. Instead of accessing physical memory, operations on ``MMIO/Register`` instances can be redirected to methods on a custom interposer object.

> Important: The interposer mechanism is a compile-time feature, active only if the `MMIO` package is built with `-DFEATURE_INTERPOSABLE`. This flag adds runtime overhead and is strictly for debug/test builds. The `MMIOInterposable` target in `swift-mmio` is pre-configured with this flag.

## The MMIOInterposer protocol

> FIXME: this section has no value over the next.

Create an interposer by defining a class conforming to ``MMIO/MMIOInterposer``:

```swift
import MMIOInterposable // Use this target for interposer-enabled builds

#if FEATURE_INTERPOSABLE
public protocol MMIOInterposer: AnyObject {
    func load<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        from pointer: UnsafePointer<Value>
    ) -> Value

    func store<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        _ value: Value, to pointer: UnsafeMutablePointer<Value>
    )
}
#endif
```

Implement `load(from:)` to simulate hardware reads and `store(_:to:)` to simulate hardware writes, potentially recording accesses or updating a test-specific memory model.

## Using an Interposer

When `FEATURE_INTERPOSABLE` is active, ``MMIO/RegisterBlock()`` and ``MMIO/Register`` initializers accept an optional `interposer` argument. An interposer passed to a `RegisterBlock` propagates to its nested members.

### 1. Define Registers

Define your peripherals and registers as usual.

```swift
import MMIOInterposable

@RegisterBlock
struct MyPeripheral {
    @RegisterBlock(offset: 0x00)
    var control: Register<Control>
    // ... other registers ...
}

@Register(bitWidth: 32)
struct Control {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var enable: ENABLE
    @ReadWrite(bits: 1..<5)
    var mode: MODE
    // ... other fields ...
}
```

### 2. Create a Custom Interposer

Implement ``MMIO/MMIOInterposer``. The following `TracingInterposer` records accesses.

> Note: The following interposer is a simplified example for demonstration only. It internally "simulates" memory as `UInt64` and is not a production-ready.

```swift
// Ensure this code is compiled only for interposable builds
#if FEATURE_INTERPOSABLE
// Represents a traced MMIO event
struct MMIOTraceEvent: Equatable {
    enum AccessType: String { case load, store }
    let type: AccessType
    let address: UInt
    let value: UInt64 // Example uses UInt64 for simulated memory
}

class TracingInterposer: MMIOInterposer {
    var trace: [MMIOTraceEvent] = []
    private var simulatedMemory: [UInt: UInt64] = [:] // Address -> Value

    func load<ValueType: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        from pointer: UnsafePointer<ValueType>
    ) -> ValueType {
        let address = UInt(bitPattern: pointer)
        let value = simulatedMemory[address, default: 0]
        trace.append(MMIOTraceEvent(type: .load, address: address, value: value))
        return ValueType(value) // Convert back to expected register width
    }

    func store<ValueType: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        _ value: ValueType,
        to pointer: UnsafeMutablePointer<ValueType>
    ) {
        let address = UInt(bitPattern: pointer)
        let storedValue = UInt64(value) // Store as common type for simulation
        simulatedMemory[address] = storedValue
        trace.append(MMIOTraceEvent(type: .store, address: address, value: storedValue))
    }
}
#endif // FEATURE_INTERPOSABLE
```

### 3. Instantiate and Use in Tests

In your test code (also compiled with `FEATURE_INTERPOSABLE`), instantiate your peripheral with the interposer. This example test verifies a sequence of register modifications.

```swift
#if FEATURE_INTERPOSABLE
import Testing

struct MyPeripheralTests {
  @Test func testMyPeripheralLogic() throws { // Using Swift Testing
    let myInterposer = TracingInterposer()
    let myAddress: UInt = 0x40010000 // Base address of the peripheral

    // Initialize the device with the interposer
    let myDevice = MyPeripheral(
        unsafeAddress: myAddress,
        interposer: myInterposer)

    // Perform operations on the device
    // 1. Modify 'enable' field.
    //   - Expected: load from 0x40010000 (simulated as 0), store 0b1.
    myDevice.control.modify { $0.enable = true }

    // 2. Modify 'mode' field, 'enable' remains true.
    //   - Expected: load from 0x40010000 (simulated as 0b1),
    //     store 0b111 (mode=3, enable=true).
    myDevice.control.modify { $0.mode = 3 }

    // Define the expected sequence of trace events
    let expectedTrace = [
      // Initial read for first modify
      MMIOTraceEvent(type: .load,  address: myAddress + 0x00, value: 0b0),
      // Write enable=true (0b1)
      MMIOTraceEvent(type: .store, address: myAddress + 0x00, value: 0b1),
      // Read for second modify (enable is 0b1)
      MMIOTraceEvent(type: .load,  address: myAddress + 0x00, value: 0b1),
      // Write mode=3 (0b0011 -> shifted to 0b0110), enable=true (0b1) -> 0b0111
      MMIOTraceEvent(type: .store, address: myAddress + 0x00, value: 0b111),
    ]
    // Assert that the recorded trace matches the expected trace
    #expect(myInterposer.trace == expectedTrace)
  }
}
#endif
```
