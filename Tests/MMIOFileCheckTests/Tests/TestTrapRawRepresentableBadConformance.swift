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

// This is an invalid conformance to BitFieldProjectable used to validate
// trapping behavior
enum Test: UInt16, BitFieldProjectable {
  static let bitWidth = 9

  case value0 = 0x0000
  case value1 = 0x0001
  case value2 = 0x01FF
}

// swift-format-ignore: AlwaysUseLowerCamelCase
//@inline(never)
public @Test func toStorage_tooSmall() {
  // CHECK-LABEL: void @"$s4main23test_toStorage_tooSmallyyF"()
  let value = Test.value0.storage(UInt8.self)
  // CHECK: call void @llvm.trap()
}

// swift-format-ignore: AlwaysUseLowerCamelCase
//@inline(never)
public @Test func fromStorage_tooSmall() {
  // CHECK-LABEL: void @"$s4main25test_fromStorage_tooSmallyyF"()
  let value = Test(storage: UInt8(0x0))
  // disabled: call void @llvm.trap()
  // disabled: llvm optimizer combines these traps for an unknown reason.
  // CHECK: call swiftcc void @"$s4main23test_toStorage_tooSmallyyF"() #0
}

// swift-format-ignore: AlwaysUseLowerCamelCase
//@inline(never)
public @Test func fromStorage_uninhabitedValue() {
  // CHECK-LABEL: void @"$s4main33test_fromStorage_uninhabitedValueyyF"()
  let value = Test(storage: UInt16(0x2))
  // disabled: call void @llvm.trap()
  // disabled: llvm optimizer combines these traps for an unknown reason.
  // CHECK: call swiftcc void @"$s4main23test_toStorage_tooSmallyyF"() #0
}
