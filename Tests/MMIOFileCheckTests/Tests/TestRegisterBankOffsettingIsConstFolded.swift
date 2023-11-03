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

@RegisterBank
struct A {
  @RegisterBank(offset: 0x100)
  var b: B
  @RegisterBank(offset: 0x800)
  var c: C
}

@RegisterBank
struct B {
  @RegisterBank(offset: 0x300)
  var r: Register<R>
}

@RegisterBank
struct C {
  @RegisterBank(offset: 0x400)
  var r: Register<R>
}

@Register(bitWidth: 64)
struct R {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 63..<64)
  var hi: HI
}

let a = A(unsafeAddress: 0x1000)

public func main() {
  a.b.r.modify { _ in }
  // CHECK: %[[#REG:]] = load volatile i64
  // CHECK-SAME: 5120
  // CHECK-NEXT: store volatile i64 %[[#REG]]
  // CHECK-SAME: 5120

  a.c.r.modify { _ in }
  // CHECK-NEXT: %[[#REG:]] = load volatile i64
  // CHECK-SAME: 7168
  // CHECK-NEXT: store volatile i64 %[[#REG]]
  // CHECK-SAME: 7168
}
