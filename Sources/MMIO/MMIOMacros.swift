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

// RegisterBank macros
@attached(member, names: named(unsafeAddress), named(init))
public macro RegisterBank() =
  #externalMacro(module: "MMIOMacros", type: "RegisterBankMacro")

@attached(accessor)
public macro RegisterBank(offset: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterBankOffsetMacro")

// Register macros
@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: RegisterLayout)
public macro Register(bitWidth: Int) =
  #externalMacro(module: "MMIOMacros", type: "RegisterMacro")

// Note: Since the 'Reserved' macro shares an implementation with the other
// bitfield macros, it can also handle the `as:` parameter found on their
// external macro declarations. However, this parameter will never be used by
// expansion for reserved bitfields, so it is omitted to avoid programmer use.
@attached(accessor)
public macro Reserved(bits: Range<Int>) =
  #externalMacro(module: "MMIOMacros", type: "ReservedMacro")

@attached(accessor)
public macro ReadWrite(bits: Range<Int>) =
  #externalMacro(module: "MMIOMacros", type: "ReadWriteMacro")

@attached(accessor)
public macro ReadOnly(bits: Range<Int>) =
  #externalMacro(module: "MMIOMacros", type: "ReadOnlyMacro")

@attached(accessor)
public macro WriteOnly(bits: Range<Int>) =
  #externalMacro(module: "MMIOMacros", type: "WriteOnlyMacro")
