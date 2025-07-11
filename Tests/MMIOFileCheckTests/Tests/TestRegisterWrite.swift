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

import MMIO

@Register(bitWidth: 8)
struct R8 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 7..<8)
  var hi: HI
}
let r8 = Register<R8>(unsafeAddress: 0x1000)

@Register(bitWidth: 16)
struct R16 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 15..<16)
  var hi: HI
}
let r16 = Register<R16>(unsafeAddress: 0x1000)

@Register(bitWidth: 32)
struct R32 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 31..<32)
  var hi: HI
}
let r32 = Register<R32>(unsafeAddress: 0x1000)

@Register(bitWidth: 64)
struct R64 {
  @ReadWrite(bits: 0..<1)
  var lo: LO
  @ReadWrite(bits: 63..<64)
  var hi: HI
}
let r64 = Register<R64>(unsafeAddress: 0x1000)

public func main8() {
  // CHECK-LABEL: void @"$s4main5main8yyF"()
  r8.write(unsafeBitCast(0 as UInt8, to: R8.Write.self))
  // CHECK: store volatile i8 0
  r8.write { $0.raw.hi = 1 }
  // CHECK: store volatile i8 -128
}

public func main16() {
  // CHECK-LABEL: void @"$s4main6main16yyF"()
  r16.write(unsafeBitCast(1 as UInt16, to: R16.Write.self))
  // CHECK: store volatile i16 1
  r16.write { $0.raw.hi = 1 }
  // CHECK: store volatile i16 -32768
}

public func main32() {
  // CHECK-LABEL: void @"$s4main6main32yyF"()
  r32.write(unsafeBitCast(2 as UInt32, to: R32.Write.self))
  // CHECK: store volatile i32 2
  r32.write { $0.raw.hi = 1 }
  // CHECK: store volatile i32 -2147483648
}

public func main64() {
  // CHECK-LABEL: void @"$s4main6main64yyF"()
  r64.write(unsafeBitCast(3 as UInt64, to: R64.Write.self))
  // CHECK: store volatile i64 3
  r64.write { $0.raw.hi = 1 }
  // CHECK: store volatile i64 -9223372036854775808
}
