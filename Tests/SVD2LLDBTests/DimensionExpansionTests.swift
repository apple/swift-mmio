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

struct DimensionExpansionTests {
  private func peripheral(
    dim: UInt64,
    dimIndex: String? = nil
  ) -> SVDPeripheral {
    .init(
      name: "Pads",
      description: "Pads with an array of registers.",
      baseAddress: 0x4003_8000,
      registerProperties: .init(),
      registers: .init(
        cluster: [],
        register: [
          .init(
            dimensionElement: .init(
              dim: dim, dimIncrement: 0x4, dimIndex: dimIndex),
            name: "GPIO%s",
            addressOffset: 0x4),
          .init(name: "SWCLK", addressOffset: 0x100),
        ]))
  }

  @Test func rangeIndex() {
    let children = peripheral(dim: 3, dimIndex: "0-2").children()
    #expect(children.map(\.name) == ["GPIO0", "GPIO1", "GPIO2", "SWCLK"])
    #expect(children.map(\.addressOffset) == [0x4, 0x8, 0xc, 0x100])
  }

  @Test func defaultIndex() {
    let children = peripheral(dim: 2).children()
    #expect(children.map(\.name) == ["GPIO0", "GPIO1", "SWCLK"])
  }

  @Test func listIndex() {
    let children = peripheral(dim: 3, dimIndex: "A,B,C").children()
    #expect(children.map(\.name) == ["GPIOA", "GPIOB", "GPIOC", "SWCLK"])
  }

  @Test func mismatchedIndexFallsBack() {
    let children = peripheral(dim: 2, dimIndex: "A,B,C").children()
    #expect(children.map(\.name) == ["GPIO0", "GPIO1", "SWCLK"])
  }

  @Test func bracketPlaceholder() {
    var register = SVDRegister(name: "CH[%s]_CTRL", addressOffset: 0)
    register.dimensionElement = .init(dim: 2, dimIncrement: 0x10)
    #expect(
      register.expandingDimensions().map(\.name) == ["CH0_CTRL", "CH1_CTRL"])
  }

  @Test func childLookupFindsArrayMember() {
    let item = peripheral(dim: 48, dimIndex: "0-47").child(at: ["gpio47"])
    #expect(item?.name == "GPIO47")
    #expect(item?.addressOffset == 0x4 + 47 * 0x4)
  }
}
