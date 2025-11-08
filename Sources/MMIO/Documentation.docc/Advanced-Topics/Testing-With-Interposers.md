# Testing with Interposers

Test your hardware interaction code without physical devices using interposers.

## Overview

Testing code that interacts with hardware registers presents unique challenges. Traditional testing approaches often require:

- Physical access to the target hardware
- Specialized debugging equipment
- Complex setup procedures to create specific hardware states

These requirements make unit testing hardware-dependent code slow, expensive, and difficult to automate. Verifying correct register interaction is crucial for reliable embedded systems.

Swift MMIO addresses this with **interposers**. An interposer intercepts memory operations that would normally target hardware registers. Instead of accessing physical memory, operations on ``MMIO/Register`` instances are redirected to methods on your custom interposer object. With interposers, you can:

- Test register interaction logic without actual hardware
- Verify sequences of register reads and writes
- Simulate specific hardware states and responses
- Automate tests that would otherwise require physical devices

> Important: The interposer mechanism is a compile-time feature, active only when the `MMIO` package is built with the `-DFEATURE_INTERPOSABLE` flag. This flag adds runtime overhead and is strictly for debug/test builds. The `MMIOInterposable` target in `swift-mmio` is pre-configured with this flag.

### Creating an Interposer

To create an interposer, define a class that conforms to the ``MMIO/MMIOInterposer`` protocol. This protocol requires you to implement two methods:

- `load(from:)`: Called when code reads from a register
- `store(_:to:)`: Called when code writes to a register

Start by creating a basic interposer that simulates memory by storing values in a dictionary. This interposer:
1. Maps memory addresses to values
2. Returns stored values on reads
3. Updates stored values on writes

First, define the class structure and storage:

```swift
import MMIOInterposable // Use this target for interposer-enabled builds

class BasicInterposer: MMIOInterposer {
    // Simulated memory storage - maps addresses to values
    private var memory: [UInt: UInt64] = [:]

    // Protocol methods will be implemented next
}
```

Next, implement the `load` method. This method is called whenever code reads from a register. It:
1. Converts the memory pointer to a numeric address
2. Looks up the value stored at that address in the simulated memory
3. Converts the value to the expected register width and returns it

```swift
class BasicInterposer: MMIOInterposer {
    // ...

    func load<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        from pointer: UnsafePointer<Value>
    ) -> Value {
        let address = UInt(bitPattern: pointer)
        let value = memory[address, default: 0]
        return Value(value)
    }
}
```

Then, implement the `store` method. This method is called whenever code writes to a register. It:
1. Converts the memory pointer to a numeric address
2. Converts the value to the simulated memory type (UInt64)
3. Stores the value in the simulated memory at the specified address

```swift
class BasicInterposer: MMIOInterposer {
    // ...

    func store<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        _ value: Value, to pointer: UnsafeMutablePointer<Value>
    ) {
        let address = UInt(bitPattern: pointer)
        memory[address] = UInt64(value)
    }
}
```

This basic interposer provides the minimum functionality needed to simulate memory-mapped registers. When code reads from an address, the interposer returns the corresponding value from the dictionary. When code writes to an address, the interposer updates the dictionary.

> Important: This implementation has limitations and is not production quality. It only supports 64-bit aligned load/store operations and doesn't handle unaligned accesses.

### Tracing Register Accesses

For testing purposes, you often need to record register accesses for later verification. Let's create an example interposer that extends the basic implementation with tracing capabilities.

This example tracing implementation:
1. Stores a record of all register accesses (reads and writes)
2. Captures the address, value, and type of each access
3. Maintains simulated memory like the basic interposer
4. Allows test code to verify the sequence of operations

First, define a structure to represent a traced memory access event:

```swift
import MMIOInterposable

struct MMIOTraceEvent {
    enum AccessType: String { case load, store }
    let type: AccessType
    let address: UInt
    let value: UInt64
}
```

Each `MMIOTraceEvent` captures:
- The type of access (load/read or store/write)
- The memory address being accessed
- The value that was read or written

Next, create the tracing interposer class:

```swift
class TracingInterposer: MMIOInterposer {
    // Record of all register accesses
    var trace: [MMIOTraceEvent] = []

    // Simulated memory storage
    private var simulatedMemory: [UInt: UInt64] = [:]
}
```

Now, implement the `load` method to record read operations. This method performs the same operations as the basic interposer, but also records each read in the trace:

```swift
class TracingInterposer: MMIOInterposer {
    // ...

    func load<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        from pointer: UnsafePointer<Value>
    ) -> Value {
        let address = UInt(bitPattern: pointer)
        let value = simulatedMemory[address, default: 0]

        // Record this read operation in the trace
        trace.append(MMIOTraceEvent(type: .load, address: address, value: value))

        return Value(value)
    }
}
```

Finally, implement the `store` method to record write operations. This method also performs the same operations as the basic interposer, but records each write in the trace:

```swift
class TracingInterposer: MMIOInterposer {
    // ...

    func store<Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage>(
        _ value: Value, to pointer: UnsafeMutablePointer<Value>
    ) {
        let address = UInt(bitPattern: pointer)
        let storedValue = UInt64(value)

        // Update simulated memory
        simulatedMemory[address] = storedValue

        // Record this write operation in the trace
        trace.append(MMIOTraceEvent(type: .store, address: address, value: storedValue))
    }
}
```

This tracing interposer records each memory operation in a `trace` array, which you can examine to verify that your code interacts with registers in the expected sequence.

### Testing with Interposers

When the `FEATURE_INTERPOSABLE` flag is active, both ``MMIO/Register`` and ``MMIO/RegisterBlock()`` initializers accept an optional `interposer` parameter. When you provide an interposer, all memory operations on that register or register block are redirected to the interposer instead of accessing physical memory.

> Note: When you pass an interposer to a register block, it automatically propagates to all contained registers and subblocks.

The real power of interposers is in verifying register access patterns. Using the `TracingInterposer` implementation created above, you can verify that your code:

- Reads from and writes to the correct registers
- Sets the correct bit patterns
- Performs operations in the correct sequence

Here's a simple example that demonstrates how to test hardware interaction code using the `TracingInterposer`.

First, define a control register:

```swift
import MMIOInterposable
import Testing

@Register(bitWidth: 32)
struct ControlRegister {
    @ReadWrite(bits: 0..<1, as: Bool.self)
    var enable: ENABLE

    @ReadWrite(bits: 1..<3)
    var mode: MODE

    @ReadWrite(bits: 3..<8)
    var prescaler: PRESCALER
}
```

Now, create a function that updates the register based on its current state:

```swift
func updateControlRegister(_ control: Register<ControlRegister>, newMode: UInt8) {
    control.modify { value in
        if !value.enable {
            value.enable = true
            value.mode = newMode
            value.prescaler = 4
        } else {
            value.mode = newMode
        }
    }
}
```

Finally, write a test that verifies the function works correctly. The test:

1. Creates a tracing interposer to record all register accesses
2. Creates a control register with the interposer at address `0x40000000`
3. Calls the `updateControlRegister` function with mode value 2
4. Verifies the sequence of register accesses:
   - First, the function should read the current register value (0 by default)
   - Then, it should write the updated value with (binary 00100001 = decimal 33):
     - enable=true
     - mode=2
     - prescaler=4

```swift
struct ControlRegisterTests {
    @Test func testUpdateWhenDisabled() throws {
        let interposer = TracingInterposer() // 1

        let control = ControlRegister(unsafeAddress: 0x40000000, interposer: interposer) // 2

        updateControlRegister(control, newMode: 2) // 3

        let expectedTrace = [
            MMIOTraceEvent(type: .load, address: 0x40000000, value: 0), // 4
            MMIOTraceEvent(type: .store, address: 0x40000000, value: 33) // 4
        ]

        #expect(interposer.trace == expectedTrace) // 4
    }
}
```
