//===----------------------------------------------------------*- swift -*-===//
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
@available(*, deprecated, renamed: "RegisterBlock()")
@attached(member, names: named(unsafeAddress), named(init), named(interposer))
public macro RegisterBank() =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockMacro")

@available(*, deprecated, renamed: "RegisterBlock(offset:)")
@attached(accessor)
public macro RegisterBank(offset: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockScalarMemberMacro")

@available(*, deprecated, renamed: "RegisterBlock(offset:stride:count:)")
@attached(accessor)
public macro RegisterBank(offset: Int, stride: Int, count: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockArrayMemberMacro")

// RegisterBlock macros
@attached(member, names: named(unsafeAddress), named(init), named(interposer))
@attached(extension, conformances: RegisterProtocol)
public macro RegisterBlock() =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockMacro")

@attached(accessor)
public macro RegisterBlock(offset: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockScalarMemberMacro")

@attached(accessor)
public macro RegisterBlock(offset: Int, stride: Int, count: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBlockArrayMemberMacro")

// Register macros
@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: RegisterValue)
public macro Register(bitWidth: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterMacro")

// Note: Since the 'Reserved' macro shares an implementation with the other
// bitfield macros, it can also handle the `as:` parameter found on their
// external macro declarations. However, this parameter will never be used by
// expansion for reserved bitfields, so it is omitted to avoid programmer use.
@attached(accessor)
public macro Reserved<Range>(bits: Range...) =
  #externalMacro(module: "MMIOMacros", type: "ReservedMacro")
where Range: RangeExpression, Range.Bound: BinaryInteger

@attached(accessor)
public macro Reserved(bits: UnboundedRange) =
  #externalMacro(module: "MMIOMacros", type: "ReservedMacro")

@attached(accessor)
public macro ReadWrite<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadWriteMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@attached(accessor)
public macro ReadWrite<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadWriteMacro")
where Value: BitFieldProjectable

@attached(accessor)
public macro ReadOnly<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadOnlyMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@attached(accessor)
public macro ReadOnly<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "ReadOnlyMacro")
where Value: BitFieldProjectable

@attached(accessor)
public macro WriteOnly<Range, Value>(
  bits: Range..., as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "WriteOnlyMacro")
where
  Range: RangeExpression, Range.Bound: BinaryInteger, Value: BitFieldProjectable

@attached(accessor)
public macro WriteOnly<Value>(
  bits: UnboundedRange, as: Value.Type = Never.self
) =
  #externalMacro(module: "MMIOMacros", type: "WriteOnlyMacro")
where Value: BitFieldProjectable
