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

import MMIO

// Sample register from an STM32F746
@Register(bitWidth: 32)
struct OTG_HPRT {
  @ReadWrite(bits: 0..<1)
  var pcsts: PCSTS
  @ReadWrite(bits: 1..<2)
  var pcdet: PCDET
  @ReadWrite(bits: 2..<3)
  var pena: PENA
  @ReadWrite(bits: 3..<4)
  var penChng: PEN_CHNG
  @ReadWrite(bits: 4..<5)
  var poca: POCA
  @ReadWrite(bits: 5..<6)
  var pocChng: POC_CHNG
  @ReadWrite(bits: 6..<7)
  var pres: PRES
  @ReadWrite(bits: 7..<8)
  var psusp: PSUSP
  @ReadWrite(bits: 8..<9)
  var prst: PRST
  @Reserved(bits: 9..<10)
  var reserved0: Reserved0
  @ReadWrite(bits: 10..<12)
  var plsts: PLSTS
  @ReadWrite(bits: 12..<13)
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

@RegisterBlock
struct Block {
  @RegisterBlock(offset: 0x4)
  var otgHprt: Register<OTG_HPRT>
  @RegisterBlock(offset: 0x8, stride: 0x10, count: 100)
  var asym: RegisterArray<SampleAsym>
}
