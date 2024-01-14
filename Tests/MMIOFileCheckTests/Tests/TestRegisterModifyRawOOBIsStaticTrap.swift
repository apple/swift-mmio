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
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 7..<8)
  var hi: HI
}
let r8 = Register<R8>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 16)
struct R16 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 15..<16)
  var hi: HI
}
let r16 = Register<R16>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 32)
struct R32 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 31..<32)
  var hi: HI
}
let r32 = Register<R32>(unsafeAddress: 0x1000)

@RegisterDescriptor(bitWidth: 64)
struct R64 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 63..<64)
  var hi: HI
}
let r64 = Register<R64>(unsafeAddress: 0x1000)

public func main8() {
  r8.modify { $0.raw.lo = 0b11 }
  // CHECK: %[[#REG:]] = load volatile i8
  // CHECK: call void @llvm.trap()
}

public func main16() {
  r16.modify { $0.raw.lo = 0b11 }
  // CHECK: %[[#REG:]] = load volatile i16
  // CHECK: call void @llvm.trap()
}

public func main32() {
  r32.modify { $0.raw.lo = 0b11 }
  // CHECK: %[[#REG:]] = load volatile i32
  // CHECK: call void @llvm.trap()
}

public func main64() {
  r64.modify { $0.raw.lo = 0b11 }
  // CHECK: %[[#REG:]] = load volatile i64
  // CHECK: call void @llvm.trap()
}
