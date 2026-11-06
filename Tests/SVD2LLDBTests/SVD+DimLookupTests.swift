//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import SVD
@testable import SVD2LLDB

struct SVDDimLookupTests {
  private let register = SVDRegister(
    name: "GPIO%s",
    description: "Dim register array",
    addressOffset: 0x10,
    dimensionElement: .init(
      dim: 4,
      dimIncrement: 0x4))

  @Test func matchesDimRegister() {
    #expect("GPIO[0]".matchesDimRegister("GPIO%s") == 0)
    #expect("GPIO[3]".matchesDimRegister("GPIO%s") == 3)
    #expect("GPIO[4]".matchesDimRegister("GPIO%s") == nil)
    #expect("GPIO".matchesDimRegister("GPIO%s") == nil)
  }

  @Test func dimIndexAndAddress() {
    #expect(register.dimIndex(for: "GPIO[2]") == 2)
    #expect(register.dimIndex(for: "GPIO[9]") == nil)
    #expect(register.address(forDimIndex: 2, baseAddress: 0x1000) == 0x1018)
  }

  @Test func peripheralRegisterLookup() {
    let peripheral = SVDPeripheral(
      name: "TestPeripheral",
      baseAddress: 0x1000,
      registers: .init(
        register: [register]))

    #expect(peripheral.register(name: "GPIO[1]")?.name == "GPIO%s")
    #expect(peripheral.register(name: "GPIO[1]")?.dimIndex(for: "GPIO[1]") == 1)
  }
}
