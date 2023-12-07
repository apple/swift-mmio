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
struct R8 {
  @ReadWrite(bits: 0..<2, as: Bool.self)
  var lo: LO
}
let r8 = Register<R8>(unsafeAddress: 0x1000)

@Register(bitWidth: 16)
struct R16 {
  @ReadWrite(bits: 0..<2, as: Bool.self)
  var lo: LO
}
let r16 = Register<R16>(unsafeAddress: 0x1000)

@Register(bitWidth: 32)
struct R32 {
  @ReadWrite(bits: 0..<2, as: Bool.self)
  var lo: LO
}
let r32 = Register<R32>(unsafeAddress: 0x1000)

@Register(bitWidth: 64)
struct R64 {
  @ReadWrite(bits: 0..<2, as: Bool.self)
  var lo: LO
}
let r64 = Register<R64>(unsafeAddress: 0x1000)

public func main8() {
  // CHECK-LABEL: void @"$s4main5main8yyF"()
  r8.modify { $0.lo = true }
  // CHECK: %0 = load volatile i8
  // CHECK: call void @llvm.trap()
}

public func main16() {
  // CHECK-LABEL: void @"$s4main6main16yyF"()
  r16.modify { $0.lo = true }
  // CHECK: %0 = load volatile i16
  // CHECK: call void @llvm.trap()
}

public func main32() {
  // CHECK-LABEL: void @"$s4main6main32yyF"()
  r32.modify { $0.lo = true }
  // CHECK: %0 = load volatile i32
  // CHECK: call void @llvm.trap()
}

public func main64() {
  // CHECK-LABEL: void @"$s4main6main64yyF"()
  r64.modify { $0.lo = true }
  // CHECK: %0 = load volatile i64
  // CHECK: call void @llvm.trap()
}
