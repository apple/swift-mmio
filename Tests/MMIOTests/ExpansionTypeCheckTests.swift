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

public import MMIO

// Sample register from an STM32F746
@Register(bitWidth: 32)
struct OTG_HPRT {
  @ReadWrite(bits: 0)
  var pcsts: PCSTS
  @ReadWrite(bits: 1)
  var pcdet: PCDET
  @ReadWrite(bits: 2)
  var pena: PENA
  @ReadWrite(bits: 3)
  var penChng: PEN_CHNG
  @ReadWrite(bits: 4)
  var poca: POCA
  @ReadWrite(bits: 5)
  var pocChng: POC_CHNG
  @ReadWrite(bits: 6)
  var pres: PRES
  @ReadWrite(bits: 7)
  var psusp: PSUSP
  @ReadWrite(bits: 8)
  var prst: PRST
  @Reserved(bits: 9)
  var reserved0: Reserved0
  @ReadWrite(bits: 10..<12)
  var plsts: PLSTS
  @ReadWrite(bits: 12)
  var ppwr: PPWR
  @ReadWrite(bits: 13..<17)
  var ptctl: PTCTL
  @ReadWrite(bits: 17..<19)
  var pspd: PSPD
  @Reserved(bits: 19..<32)
  var reserved1: Reserved1
}

@Register(bitWidth: 32)
struct SampleAsym {
  @Reserved(bits: 0..<1)
  var re: RE
  @ReadOnly(bits: 1..<2)
  var ro: RO
  @WriteOnly(bits: 2..<3)
  var wo: WO
  @ReadWrite(bits: 3..<4)
  var rw: RW
}

@Register(bitWidth: 32)
struct OtherRangeTypes0 {
  @Reserved(bits: ...)
  var unbounded: Unbounded
}

@Register(bitWidth: 32)
struct OtherRangeTypes1 {
  @Reserved(bits: ...16)
  var partialThrough: PartialThrough
  @Reserved(bits: 17...)
  var partialFrom: PartialFrom
}

@Register(bitWidth: 32)
struct OtherRangeTypes2 {
  @Reserved(bits: ..<16)
  var partialUpTo: PartialUpTo
  @Reserved(bits: 16...31)
  var closed: Closed
}

@Register(bitWidth: 32)
struct MixedRangeTypes {
  @Reserved(bits: ..<2, 4...5, 8..<10, 30...)
  var mixed: Mixed
}

@Register(bitWidth: 32)
struct OtherRangeTypes3 {
  @Reserved(bits: 0)
  var index: Index
  @ReadOnly(bits: 1, 3, as: UInt8.self)
  var discontiguousIndices: DiscontiguousIndices
  @WriteOnly(bits: 2, as: Bool.self)
  var writeOnlyIndex: WriteOnlyIndex
  @ReadWrite(bits: 4, 0x1f)
  var hexadecimalIndices: HexadecimalIndices
  @ReadWrite(bits: 5, 8..<10, 12...13, as: UInt8.self)
  var mixedIndicesAndRanges: MixedIndicesAndRanges
  @ReadWrite(bits: 14, 16..<31)
  var mixedIndexAndRange: MixedIndexAndRange
}

@Register(bitWidth: 32)
struct RegisterWithValues {
  struct FieldValues: BitFieldProjectable, RawRepresentable {
    static let bitWidth = 2
    var rawValue: UInt8
    @inlinable @inline(__always)
    init(rawValue: Self.RawValue) {
      self.rawValue = rawValue
    }
  }

  @ReadWrite(bits: ..<2, as: FieldValues.self)
  var reg: Field
}

@RegisterBlock
struct Block {
  @RegisterBlock(offset: 0x4)
  var otgHprt: Register<OTG_HPRT>
  @RegisterBlock(offset: 0x8, stride: 0x10, count: 100)
  var asym: RegisterArray<SampleAsym>
}

// Public, so that Swift does not infer `Sendable` for these types. The
// conformance must come from the `@Register` macro.
@Register(bitWidth: 32)
public struct PublicSymmetric {
  @ReadWrite(bits: 0..<32)
  public var field: FIELD
}

@Register(bitWidth: 32)
public struct PublicAsymmetric {
  @ReadOnly(bits: 0..<16)
  public var ro: RO
  @WriteOnly(bits: 16..<32)
  public var wo: WO
}

// Fails to compile if register values are not Sendable.
private let sendableTypes: [any Sendable.Type] = [
  PublicSymmetric.self,
  PublicSymmetric.Raw.self,
  PublicSymmetric.ReadWrite.self,
  PublicAsymmetric.self,
  PublicAsymmetric.Raw.self,
  PublicAsymmetric.Read.self,
  PublicAsymmetric.Write.self,
]
