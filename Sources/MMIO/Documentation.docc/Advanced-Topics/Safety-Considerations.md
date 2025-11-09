# Safety Considerations

Understand Swift MMIO's guarantees and developer responsibilities.

## Overview

Swift MMIO is safer and more ergonomic than traditional low-level programming in C. However, direct hardware interaction still requires careful attention. This article covers Swift MMIO's safety model and what you're responsible for.

### Developer responsibilities

Swift MMIO provides significant safety improvements, but direct hardware interaction has inherent risks. You're responsible for:

1.  **Correct Base Addresses (`unsafeAddress`):**
    Providing the correct base memory address for a `RegisterBlock` or ``MMIO/Register`` is critical. An incorrect address can lead to accessing unintended memory, wrong peripherals, system faults, or data corruption. Always verify addresses against official hardware documentation.

2.  **Accurate Register Layout Definitions:**
    ``MMIO/Register(bitWidth:)`` definitions (total `bitWidth`, field offsets, widths, access types via macros like ``MMIO/ReadWrite(bits:as:)``) must match hardware documentation exactly. Mismatched layouts cause misinterpreted status, incorrect control signals, or unintended modification of adjacent fields/registers. Use `SVD2Swift` with vendor/community-vetted SVD files when possible to reduce manual errors.

3.  **Understanding Hardware Side Effects:**
    MMIO register access can have side effects (read-to-clear flags, triggering operations, state-dependent permissions, timing requirements). Ignoring these leads to missed events, incorrect state transitions, or hardware errors. Consult datasheets for side effects and handle them in your code (polling, interrupt handlers, delays). Swift MMIO ensures volatile memory access but can't guarantee logical correctness.

### Library responsibilities

Swift MMIO offers several safety layers:

1.  **Type Safety:**
    Type projections (via ``MMIO/BitFieldProjectable``) represent bit fields as strong Swift types, preventing out-of-range or meaningless integer assignments.

2.  **Compile-Time Boundary Checking for Fields:**
    Bit field definitions are checked at compile-time to be within their parent ``MMIO/Register(bitWidth:)``'s `bitWidth`.

3.  **Runtime Checks for Field Access:**
    Writing values too large for a field's width triggers a runtime trap, preventing unintentional modification of adjacent bits.

4.  **Volatile Access Guarantee:**
    All ``MMIO/Register`` operations use volatile memory semantics, preventing incorrect compiler optimizations for MMIO. See <doc:Volatile-Access>.

5.  **Reduced Boilerplate and Manual Bit Manipulation:**
    Bit field macros generate code for bit masking and shifting automatically, avoiding common manual bitwise manipulation errors.

6.  **Clear Access Semantics:**
    Bit field macros document intended access patterns and influence the generated API (e.g., no setter for projected `ReadOnly` fields in `Write` view).

7.  **Prevention of Unintended Read-Modify-Write Cycles:**
    - Swift MMIO's API design, particularly ``MMIO/Register/modify(_:)``, prevents a common pitfall in C-style MMIO access. In C, using a `volatile` pointer to a struct with bitfields like this:
      ```c
      // C example of potential unintended multiple RMWs
      volatile MyRegisterType* myReg = (MyRegisterType*)0x40001000;
      myReg->fieldA = 1; // Could be one RMW operation
      myReg->fieldB = 2; // Could be another RMW operation
      ```
      can inadvertently trigger two distinct read-modify-write sequences on the hardware register. Each bitfield assignment is a separate load of the entire register, modification of the relevant bits, and store back. Multiple RMWs cause glitches if hardware requires simultaneous field updates or lead to incorrect behavior if register state changes between operations.
    - Swift MMIO's `modify` operation avoids this. When you write:
      ```swift
      myRegister.modify { view in
          view.fieldA = valueA
          view.fieldB = valueB
      }
      ```
      Swift MMIO performs a single volatile read before the closure, allows modifications to an in-cpu-memory representation inside the closure, then performs a single volatile write after. This ensures `fieldA` and `fieldB` (and all other register fields) are updated in hardware as one coherent register write.
