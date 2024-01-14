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

@RegisterDescriptor(bitWidth: 8)
struct R8 {
  @ReadWrite(bits: 0..<1, as: Bool.self)
  var lo: LO
  @ReadWrite(bits: 7..<8, as: Bool.self)
  var hi: HI
}
let r8 = Register<R8>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 16)
struct R16 {
  @ReadWrite(bits: 0..<1, as: Bool.self)
  var lo: LO
  @ReadWrite(bits: 15..<16, as: Bool.self)
  var hi: HI
}
let r16 = Register<R16>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 32)
struct R32 {
  @ReadWrite(bits: 0..<1, as: Bool.self)
  var lo: LO
  @ReadWrite(bits: 31..<32, as: Bool.self)
  var hi: HI
}
let r32 = Register<R32>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 64)
struct R64 {
  @ReadWrite(bits: 0..<1, as: Bool.self)
  var lo: LO
  @ReadWrite(bits: 63..<64, as: Bool.self)
  var hi: HI
}
let r64 = Register<R64>(unsafeAddress: 0x1000)

public func main8() {
  r8.modify {
    $0.lo = false
    $0.hi = false
  }
  // CHECK: %[[#REG:]] = load volatile i8
  // CHECK-NEXT: %[[#REG+1]] = and i8 %[[#REG]], 126
  // CHECK-NEXT: store volatile i8 %[[#REG+1]]
}

public func main16() {
  r16.modify {
    $0.lo = false
    $0.hi = false
  }
  // CHECK: %[[#REG:]] = load volatile i16
  // CHECK-NEXT: %[[#REG+1]] = and i16 %[[#REG]], 32766
  // CHECK-NEXT: store volatile i16 %[[#REG+1]]
}

public func main32() {
  r32.modify {
    $0.lo = false
    $0.hi = false
  }
  // CHECK: %[[#REG:]] = load volatile i32
  // CHECK-NEXT: %[[#REG+1]] = and i32 %[[#REG]], 2147483646
  // CHECK-NEXT: store volatile i32 %[[#REG+1]]
}

public func main64() {
  r64.modify {
    $0.lo = false
    $0.hi = false
  }
  // CHECK: %[[#REG:]] = load volatile i64
  // CHECK-NEXT: %[[#REG+1]] = and i64 %[[#REG]], 9223372036854775806
  // CHECK-NEXT: store volatile i64 %[[#REG+1]]
}
