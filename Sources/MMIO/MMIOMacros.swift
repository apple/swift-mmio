//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// Deprecated RegisterBank macros
@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use @RegisterBlock() instead.",
  renamed: "RegisterBlock()"
)
@attached(member, names: named(unsafeAddress), named(init), named(interposer))
public macro RegisterBank() =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockMacro")

@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use @RegisterBlock(offset:) instead.",
  renamed: "RegisterBlock(offset:)"
)
@attached(accessor)
public macro RegisterBank(offset: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockScalarMemberMacro")

@_documentation(visibility: internal)
@available(
  *, deprecated, message: "Use @RegisterBlock(offset:stride:count:) instead.",
  renamed: "RegisterBlock(offset:stride:count:)"
)
@attached(accessor)
public macro RegisterBank(offset: Int, stride: Int, count: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockArrayMemberMacro")

// MARK: - RegisterBlock macros

/// Defines a group of memory-mapped registers, such as a hardware peripheral or
/// a logical section within it.
///
/// Attach this macro to a `struct` to generate essential properties for MMIO
/// operations, including `unsafeAddress` for the base address and an
/// initializer. Members within this struct that represent individual registers
/// or nested register blocks must be annotated with ``RegisterBlock(offset:)``
/// for single elements or ``RegisterBlock(offset:stride:count:)`` for arrays of
/// elements.
///
/// For a comprehensive guide on defining peripheral layouts, see
/// <doc:Register-Blocks>.
@attached(
  member, names: named(unsafeAddress), named(init), named(interposer),
  named(_interposer))
@attached(extension, conformances: RegisterProtocol)
public macro RegisterBlock() =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockMacro")

/// Defines a single register or a nested register block within a parent
/// ``MMIO/RegisterBlock()``.
///
/// Use this macro to structure individual hardware registers or cohesive
/// sub-units within a larger peripheral definition.
///
/// - Parameter offset: The byte offset of this register or register block,
///   relative to the base address of the enclosing register block.
@attached(accessor)
public macro RegisterBlock(offset: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockScalarMemberMacro")

/// Defines an array of registers or nested register blocks within a parent
/// ``MMIO/RegisterBlock()``.
///
/// This macro is used for defining repetitive hardware structures, such as
/// multiple identical channels or a series of configuration registers. The
/// annotated property should be of type ``MMIO/RegisterArray``.
///
/// - Parameters:
///   - offset: The byte offset of the first element in the array, relative to
///     the base address of the enclosing register block.
///   - stride: The byte distance from the start of one element in the
///     array to the start of the next. This is often the size of the element
///     type but can be larger if there's padding between elements in the
///     hardware memory layout.
///   - count: The total number of elements in the array.
@attached(accessor)
public macro RegisterBlock(offset: Int, stride: Int, count: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockArrayMemberMacro")

// MARK: - Register macros

/// Defines the bit-level layout of an individual hardware register.
///
/// Attach this macro to a `struct`. The struct contains properties
/// that define individual bit fields, using macros such as
/// ``MMIO/ReadWrite(bits:as:)``, ``MMIO/ReadOnly(bits:as:)``,
/// ``MMIO/WriteOnly(bits:as:)``, and ``MMIO/Reserved(bits:as:)``. This macro
/// automatically makes the struct conform to the ``MMIO/RegisterValue``
/// protocol, enabling its use with ``MMIO/Register`` instances.
///
/// - Parameter bitWidth: The total width of the register in bits (e.g., 8, 16,
///   32, or 64). This value must accurately reflect the size of the actual
///   hardware register.
///
/// For detailed usage examples and explanations, refer to <doc:Registers>.
@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: RegisterValue)
public macro Register(bitWidth: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterMacro")

/// Defines reserved bit field within a hardware register.
///
/// Reserved bits are parts of a register that are typically unused, have
/// hardware-defined behavior, or are set aside for future use by the hardware
/// vendor. Software should generally avoid writing to reserved bits unless
/// explicitly instructed by the hardware documentation.
///
/// - Parameters:
///   - bits: A `RangeExpression` (e.g., `0..<4` for bits 0, 1, 2, and 3)
///     or a comma-separated list of range expressions. Use `...` if the field
///     spans the entire register.
///   - as: An optional type conforming to ``BitFieldProjectable`` For example,
///     can use `Bool`.self for single-bit flags, or a custom enumeration for
///     multi-bit fields representing specific states.
///
/// For detailed usage examples and explanations, refer to <doc:Registers>.
@attached(accessor)
public macro Reserved<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReservedMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@_documentation(visibility: internal)
@attached(accessor)
public macro Reserved<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReservedMacro")
where Value: BitFieldProjectable

/// Defines a read-write bit field within a register.
///
/// Bits within this field can be both read from and written to by software.
///
/// - Parameters:
///   - bits: A `RangeExpression` (e.g., `0..<4` for bits 0, 1, 2, and 3)
///     or a comma-separated list of range expressions. Use `...` if the field
///     spans the entire register.
///   - as: An optional type conforming to ``BitFieldProjectable`` For example,
///     can use `Bool`.self for single-bit flags, or a custom enumeration for
///     multi-bit fields representing specific states.
///
/// For detailed usage examples and explanations, refer to <doc:Registers>.
@attached(accessor)
public macro ReadWrite<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadWriteMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@_documentation(visibility: internal)
@attached(accessor)
public macro ReadWrite<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadWriteMacro")
where Value: BitFieldProjectable

/// Defines a read-only bit field within a register.
///
/// The value of this field is determined by the hardware and can only be read
/// by software. Attempting to write to a read-only field typically has no
/// effect or is an error, depending on the hardware.
///
/// - Parameters:
///   - bits: A `RangeExpression` (e.g., `0..<4` for bits 0, 1, 2, and 3)
///     or a comma-separated list of range expressions. Use `...` if the field
///     spans the entire register.
///   - as: An optional type conforming to ``BitFieldProjectable`` For example,
///     can use `Bool`.self for single-bit flags, or a custom enumeration for
///     multi-bit fields representing specific states.
///
/// For detailed usage examples and explanations, refer to <doc:Registers>.
@attached(accessor)
public macro ReadOnly<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadOnlyMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@_documentation(visibility: internal)
@attached(accessor)
public macro ReadOnly<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadOnlyMacro")
where Value: BitFieldProjectable

/// Defines a write-only bit field within a register.
///
/// This field can only be written to by software. Reading from a write-only
/// field might return an undefined value, always read as zero, or trigger
/// specific hardware side effects, as defined by the hardware documentation.
///
/// - Parameters:
///   - bits: A `RangeExpression` (e.g., `0..<4` for bits 0, 1, 2, and 3)
///     or a comma-separated list of range expressions. Use `...` if the field
///     spans the entire register.
///   - as: An optional type conforming to ``BitFieldProjectable`` For example,
///     can use `Bool`.self for single-bit flags, or a custom enumeration for
///     multi-bit fields representing specific states.
///
/// For detailed usage examples and explanations, refer to <doc:Registers>.
@attached(accessor)
public macro WriteOnly<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "WriteOnlyMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@_documentation(visibility: internal)
@attached(accessor)
public macro WriteOnly<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "WriteOnlyMacro")
where Value: BitFieldProjectable
