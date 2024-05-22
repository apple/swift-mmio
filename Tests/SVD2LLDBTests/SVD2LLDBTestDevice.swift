//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@testable import SVD

let device = SVDDevice(
  name: "TestDevice",
  description: "A device to test the svd2lldb lldb plugin.",
  addressUnitBits: 8,
  width: 32,
  registerProperties: .init(
    size: 32),
  peripherals: .init(
    peripheral: [
      .init(
        dimensionElement: .init(),
        name: "TestPeripheral",
        description: "A perisperhal with some registers.",
        baseAddress: 0x1000,
        registerProperties: .init(),
        registers: .init(
          cluster: [],
          register: [
            .init(
              name: "TestRegister0",
              description: "A simple register with fields.",
              addressOffset: 0x0,
              fields: .init(
                field: [
                  .init(
                    name: "Field0",
                    bitRange: .lsbMsb(.init(lsb: 1, msb: 4))),
                  .init(
                    name: "Field1",
                    bitRange: .lsbMsb(.init(lsb: 7, msb: 7))),
                ])),
            .init(
              name: "TestRegister1",
              description: "A simple register without fields.",
              addressOffset: 0x4,
              registerProperties: .init(size: 16)),
            .init(
              name: "TestRegister2",
              addressOffset: 0x8,
              readAction: .clear),
            .init(
              name: "TestRegister3",
              addressOffset: 0x12,
              fields: .init(field: fields)),
          ]))
    ]))

let mask: UInt64 = 18_446_744_073_709_551_615

private let fields: [SVDField] = [
  .init(
    name: "S",
    bitRange: .lsbMsb(.init(lsb: 31, msb: 31)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "STOP", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "START", data: .value(.init(value: .init(value: 1, mask: mask)))),
      ])),
  .init(
    name: "IDR",
    bitRange: .lsbMsb(.init(lsb: 26, msb: 27)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "KEEP", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "INCREMENT", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "DECREMENT", data: .value(.init(value: .init(value: 2, mask: mask)))),
      ])),
  .init(
    name: "RELOAD",
    bitRange: .lsbMsb(.init(lsb: 24, msb: 25)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "RELOAD0", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "RELOAD1", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "RELOAD2", data: .value(.init(value: .init(value: 2, mask: mask)))),
        .init(name: "RELOAD3", data: .value(.init(value: .init(value: 3, mask: mask)))),
      ])),
  .init(
    name: "TRGEXT",
    bitRange: .lsbMsb(.init(lsb: 20, msb: 21)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "NONE", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "DMA1", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "DMA2", data: .value(.init(value: .init(value: 2, mask: mask)))),
        .init(name: "UART", data: .value(.init(value: .init(value: 3, mask: mask)))),
      ])),
  .init(
    name: "CAPEDGE",
    bitRange: .lsbMsb(.init(lsb: 16, msb: 17)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "RISING", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "FALLING", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "BOTH", data: .value(.init(value: .init(value: 2, mask: mask)))),
      ])),
  .init(
    name: "CAPSRC",
    bitRange: .lsbMsb(.init(lsb: 12, msb: 15)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "CClk", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "GPIOA_0", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "GPIOA_1", data: .value(.init(value: .init(value: 2, mask: mask)))),
        .init(name: "GPIOA_2", data: .value(.init(value: .init(value: 3, mask: mask)))),
        .init(name: "GPIOA_3", data: .value(.init(value: .init(value: 4, mask: mask)))),
        .init(name: "GPIOA_4", data: .value(.init(value: .init(value: 5, mask: mask)))),
        .init(name: "GPIOA_5", data: .value(.init(value: .init(value: 6, mask: mask)))),
        .init(name: "GPIOA_6", data: .value(.init(value: .init(value: 7, mask: mask)))),
        .init(name: "GPIOA_7", data: .value(.init(value: .init(value: 8, mask: mask)))),
        .init(name: "GPIOB_0", data: .value(.init(value: .init(value: 9, mask: mask)))),
        .init(name: "GPIOB_1", data: .value(.init(value: .init(value: 10, mask: mask)))),
        .init(name: "GPIOB_2", data: .value(.init(value: .init(value: 11, mask: mask)))),
        .init(name: "GPIOB_3", data: .value(.init(value: .init(value: 12, mask: mask)))),
        .init(name: "GPIOC_0", data: .value(.init(value: .init(value: 13, mask: mask)))),
        .init(name: "GPIOC_5", data: .value(.init(value: .init(value: 14, mask: mask)))),
        .init(name: "GPIOC_6", data: .value(.init(value: .init(value: 15, mask: mask)))),
      ])),
  .init(
    name: "CNTSRC",
    bitRange: .lsbMsb(.init(lsb: 8, msb: 11)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "CAP_SRC", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "CAP_SRC_div2", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "CAP_SRC_div4", data: .value(.init(value: .init(value: 2, mask: mask)))),
        .init(name: "CAP_SRC_div8", data: .value(.init(value: .init(value: 3, mask: mask)))),
        .init(name: "CAP_SRC_div16", data: .value(.init(value: .init(value: 4, mask: mask)))),
        .init(name: "CAP_SRC_div32", data: .value(.init(value: .init(value: 5, mask: mask)))),
        .init(name: "CAP_SRC_div64", data: .value(.init(value: .init(value: 6, mask: mask)))),
        .init(name: "CAP_SRC_div128", data: .value(.init(value: .init(value: 7, mask: mask)))),
        .init(name: "CAP_SRC_div256", data: .value(.init(value: .init(value: 8, mask: mask)))),
      ])),
  .init(
    name: "PSC",
    bitRange: .lsbMsb(.init(lsb: 7, msb: 7)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "Disabled", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "Enabled", data: .value(.init(value: .init(value: 1, mask: mask)))),
      ])),
  .init(
    name: "MODE",
    bitRange: .lsbMsb(.init(lsb: 4, msb: 6)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "Continous", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "Single_ZERO_MAX", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "Single_MATCH", data: .value(.init(value: .init(value: 2, mask: mask)))),
        .init(name: "Reload_ZERO_MAX", data: .value(.init(value: .init(value: 3, mask: mask)))),
        .init(name: "Reload_MATCH", data: .value(.init(value: .init(value: 4, mask: mask)))),
      ])),
  .init(
    name: "CNT",
    bitRange: .lsbMsb(.init(lsb: 2, msb: 3)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "Count_UP", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "Count_DOWN", data: .value(.init(value: .init(value: 1, mask: mask)))),
        .init(name: "Toggle", data: .value(.init(value: .init(value: 2, mask: mask)))),
      ])),
  .init(
    name: "RST",
    bitRange: .lsbMsb(.init(lsb: 1, msb: 1)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "Reserved", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "Reset_Timer", data: .value(.init(value: .init(value: 1, mask: mask)))),
      ])),
  .init(
    name: "EN",
    bitRange: .lsbMsb(.init(lsb: 0, msb: 0)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(name: "Disable", data: .value(.init(value: .init(value: 0, mask: mask)))),
        .init(name: "Enable", data: .value(.init(value: .init(value: 1, mask: mask)))),
      ])),
]
