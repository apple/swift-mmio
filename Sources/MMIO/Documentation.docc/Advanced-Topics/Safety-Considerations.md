# Safety Considerations

Understand Swift MMIO's guarantees and developer responsibilities.

## Overview

Swift MMIO improves the safety and ergonomics of memory-mapped I/O operations compared to traditional low-level programming in languages like C. However, direct hardware interaction inherently involves aspects that require careful attention from you. This article discusses the safety model and performance characteristics of Swift MMIO.

## Safety

### Developer Responsibilities (Unsafe Aspects)

While Swift MMIO introduces significant safety improvements, certain aspects remain inherently unsafe due to the nature of direct hardware interaction. You are responsible for:

1.  **Correct Base Addresses (`unsafeAddress`):**
    Providing the correct base memory address for a `RegisterBlock` or ``MMIO/Register`` is critical. An incorrect address can lead to accessing unintended memory, wrong peripherals, system faults, or data corruption. Always verify addresses against official hardware documentation.

2.  **Accurate Register Layout Definitions:**
    Definitions for ``MMIO/Register(bitWidth:)`` types (total `bitWidth`, field offsets, widths, access types via macros like ``MMIO/ReadWrite(bits:as:)``) must precisely match hardware documentation. Mismatched layouts can cause misinterpretation of status, incorrect control signals, or unintended modification of adjacent fields/registers. Use tools like `SVD2Swift` with vendor/community-vetted SVD files where possible to reduce manual errors.

3.  **Understanding Hardware Side Effects:**
    MMIO register access can have side effects (e.g., read-to-clear flags, initiating time-consuming operations, state-dependent access permissions, timing requirements). Ignoring these can lead to missed events, incorrect state transitions, or hardware errors. Consult datasheets for side effects and manage them in your logic (e.g., polling, interrupt handlers, delays). Swift MMIO ensures volatile memory access but not the logical consequences of that access.

### Safety Provided by Swift MMIO

Swift MMIO offers several safety layers:

1.  **Type Safety:**
    Type projections (via ``MMIO/BitFieldProjectable``) allow bit fields to be represented by strong Swift types, preventing out-of-range/meaningless integer assignments.

2.  **Compile-Time Boundary Checking for Fields:**
    Bit field definitions are checked at compile-time to be within their parent ``MMIO/Register(bitWidth:)``'s `bitWidth`.

3.  **Runtime Checks for Field Access:**
    Writing a values too large for a field's width triggers a runtime trap, preventing unintentional modification of adjacent bits.

4.  **Volatile Access Guarantee:**
    All ``MMIO/Register`` operations use volatile memory semantics, preventing incorrect compiler optimizations for MMIO. See <doc:Volatile-Access>.

5.  **Reduced Boilerplate and Manual Bit Manipulation:**
    Bit field macros automatically generate the necessary code for bit masking and shifting, avoiding common errors found in manual bitwise manipulation.

6.  **Clear Access Semantics:**
    Bit field macros document intended access patterns and influence the generated API (e.g., no setter for projected `ReadOnly` fields in `Write` view).

7.  **Prevention of Unintended Read-Modify-Write Cycles:**
    - Swift MMIO's API design, particularly the ``MMIO/Register/modify(_:)`` method, helps prevent a common pitfall found in C-style MMIO access. In C, using a `volatile` pointer to a struct with bitfields, code like:
      ```c
      // C example of potential unintended multiple RMWs
      volatile MyRegisterType* myReg = (MyRegisterType*)0x40001000;
      myReg->fieldA = 1; // Could be one RMW operation
      myReg->fieldB = 2; // Could be another RMW operation
      ```
      can inadvertently result in two distinct read-modify-write sequences on the hardware register. This happens because each assignment to a bitfield member is a separate load of the entire register, modification of the relevant bits, and a store of the entire register. Such multiple RMWs can cause glitches if hardware requires fields to be updated simultaneously or can lead to incorrect behavior if the register state changes between the operations.
    - Swift MMIO's `modify` operation avoids this. When you write:
      ```swift
      myRegister.modify { view in
          view.fieldA = valueA
          view.fieldB = valueB
      }
      ```
      Swift MMIO performs a single volatile read of the entire register before the closure, allows modifications to an in-memory representation within the closure, and then performs a single volatile write of the combined result after the closure. This ensures that `fieldA` and `fieldB` (and any other fields modified within the closure) are updated in the hardware as part of one coherent register write.
