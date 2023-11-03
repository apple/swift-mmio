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

@Register(bitWidth: 8)
struct S8 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 7..<8)
  var hi: HI
}
let s8 = Register<S8>(unsafeAddress: 0x1000)

@Register(bitWidth: 16)
struct S16 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 15..<16)
  var hi: HI
}
let s16 = Register<S16>(unsafeAddress: 0x1000)

@Register(bitWidth: 32)
struct S32 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 31..<32)
  var hi: HI
}
let s32 = Register<S32>(unsafeAddress: 0x1000)

@Register(bitWidth: 64)
struct S64 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 63..<64)
  var hi: HI
}
let s64 = Register<S64>(unsafeAddress: 0x1000)

public func main() {
  s8.modify {
    $0.lo = 0
    $0.hi = 0
  }
  // CHECK: %[[#REG:]] = load volatile i8
  // CHECK-NEXT: %[[#REG+1]] = and i8 %[[#REG]], 126
  // CHECK-NEXT: store volatile i8 %[[#REG+1]]

  s16.modify {
    $0.lo = 0
    $0.hi = 0
  }
  // CHECK: %[[#REG:]] = load volatile i16
  // CHECK-NEXT: %[[#REG+1]] = and i16 %[[#REG]], 32766
  // CHECK-NEXT: store volatile i16 %[[#REG+1]]

  s32.modify {
    $0.lo = 0
    $0.hi = 0
  }
  // CHECK: %[[#REG:]] = load volatile i32
  // CHECK-NEXT: %[[#REG+1]] = and i32 %[[#REG]], 2147483646
  // CHECK-NEXT: store volatile i32 %[[#REG+1]]

  s64.modify {
    $0.lo = 0
    $0.hi = 0
  }
  // CHECK: %[[#REG:]] = load volatile i64
  // CHECK-NEXT: %[[#REG+1]] = and i64 %[[#REG]], 9223372036854775806
  // CHECK-NEXT: store volatile i64 %[[#REG+1]]
}
