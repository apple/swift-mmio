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

@Register(bitWidth: 32)
struct Foo {
  @ReadWrite(bits: 0..<8)
  var dr: DR
}

@Register(bitWidth: 32)
struct OTG_HPRT {
  @ReadWrite(bits: 0..<1)
  var pcsts: PCSTS
  @ReadWrite(bits: 1..<2)
  var pcdet: PCDET
  @ReadWrite(bits: 2..<3)
  var pena: PENA
  @ReadWrite(bits: 3..<4)
  var pen_chng: PEN_CHNG
  @ReadWrite(bits: 4..<5)
  var poca: POCA
  @ReadWrite(bits: 5..<6)
  var poc_chng: POC_CHNG
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

@RegisterBank
struct Bank {
  @RegisterBank(offset: 0x0)
  var foo: Register<Foo>
  @RegisterBank(offset: 0x4)
  var otg_hprt: Register<OTG_HPRT>
  @RegisterBank(offset: 0x8)
  var asym: Register<Asym>
}

var bank = Bank(unsafeAddress: 0x1000)
bank.foo.modify { r, w in w.dr |= 1 }

bank.foo.modify { $0.dr |= 1 }

@Register(bitWidth: 32)
struct Asym {
  @Reserved(bits: 0..<1)
  var re: RE
  @ReadOnly(bits: 1..<2)
  var ro: RO
  @WriteOnly(bits: 2..<3)
  var wo: WO
  @ReadWrite(bits: 3..<4)
  var rw: RW
}



bank.asym.modify { r, w in
  print(r.ro)
  print(r.rw)
  print(w.wo)
  print(w.rw)
}


/*

 struct X {

 }


 struct X.R {

 }

 struct X.W {
  var _storage: UInt32
  ///
  var pcsts: Bool {
    // deprecated, dont do this, you're likely wrong.
    get {}
  }
  /// code comment about this value not being the same as the read value
  var _pcsts: UInt32 {
    // ok, shoot yourself (in the foot) if you want?
    get { }
  }

  var _reserved0: UInt32 { }
 }


 */
