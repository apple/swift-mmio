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

let previewMask: UInt64 = 18_446_744_073_709_551_615

let previewFields: [SVDField] = [
  .init(
    name: "S",
    bitRange: .lsbMsb(.init(lsb: 31, msb: 31)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "STOP",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "START",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
      ])),
  .init(
    name: "IDR",
    bitRange: .lsbMsb(.init(lsb: 26, msb: 27)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "KEEP",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "INCREMENT",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "DECREMENT",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
      ])),
  .init(
    name: "RELOAD",
    bitRange: .lsbMsb(.init(lsb: 24, msb: 25)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "RELOAD0",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "RELOAD1",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "RELOAD2",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
        .init(
          name: "RELOAD3",
          data: .value(.init(value: .init(value: 3, mask: previewMask)))),
      ])),
  .init(
    name: "TRGEXT",
    bitRange: .lsbMsb(.init(lsb: 20, msb: 21)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "NONE",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "DMA1",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "DMA2",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
        .init(
          name: "UART",
          data: .value(.init(value: .init(value: 3, mask: previewMask)))),
      ])),
  .init(
    name: "CAPEDGE",
    bitRange: .lsbMsb(.init(lsb: 16, msb: 17)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "RISING",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "FALLING",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "BOTH",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
      ])),
  .init(
    name: "CAPSRC",
    bitRange: .lsbMsb(.init(lsb: 12, msb: 15)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "CClk",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "GPIOA_0",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "GPIOA_1",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
        .init(
          name: "GPIOA_2",
          data: .value(.init(value: .init(value: 3, mask: previewMask)))),
        .init(
          name: "GPIOA_3",
          data: .value(.init(value: .init(value: 4, mask: previewMask)))),
        .init(
          name: "GPIOA_4",
          data: .value(.init(value: .init(value: 5, mask: previewMask)))),
        .init(
          name: "GPIOA_5",
          data: .value(.init(value: .init(value: 6, mask: previewMask)))),
        .init(
          name: "GPIOA_6",
          data: .value(.init(value: .init(value: 7, mask: previewMask)))),
        .init(
          name: "GPIOA_7",
          data: .value(.init(value: .init(value: 8, mask: previewMask)))),
        .init(
          name: "GPIOB_0",
          data: .value(.init(value: .init(value: 9, mask: previewMask)))),
        .init(
          name: "GPIOB_1",
          data: .value(.init(value: .init(value: 10, mask: previewMask)))),
        .init(
          name: "GPIOB_2",
          data: .value(.init(value: .init(value: 11, mask: previewMask)))),
        .init(
          name: "GPIOB_3",
          data: .value(.init(value: .init(value: 12, mask: previewMask)))),
        .init(
          name: "GPIOC_0",
          data: .value(.init(value: .init(value: 13, mask: previewMask)))),
        .init(
          name: "GPIOC_5",
          data: .value(.init(value: .init(value: 14, mask: previewMask)))),
        .init(
          name: "GPIOC_6",
          data: .value(.init(value: .init(value: 15, mask: previewMask)))),
      ])),
  .init(
    name: "CNTSRC",
    bitRange: .lsbMsb(.init(lsb: 8, msb: 11)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "CAP_SRC",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div2",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div4",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div8",
          data: .value(.init(value: .init(value: 3, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div16",
          data: .value(.init(value: .init(value: 4, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div32",
          data: .value(.init(value: .init(value: 5, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div64",
          data: .value(.init(value: .init(value: 6, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div128",
          data: .value(.init(value: .init(value: 7, mask: previewMask)))),
        .init(
          name: "CAP_SRC_div256",
          data: .value(.init(value: .init(value: 8, mask: previewMask)))),
      ])),
  .init(
    name: "PSC",
    bitRange: .lsbMsb(.init(lsb: 7, msb: 7)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "Disabled",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "Enabled",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
      ])),
  .init(
    name: "MODE",
    bitRange: .lsbMsb(.init(lsb: 4, msb: 6)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "Continous",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "Single_ZERO_MAX",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "Single_MATCH",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
        .init(
          name: "Reload_ZERO_MAX",
          data: .value(.init(value: .init(value: 3, mask: previewMask)))),
        .init(
          name: "Reload_MATCH",
          data: .value(.init(value: .init(value: 4, mask: previewMask)))),
      ])),
  .init(
    name: "CNT",
    bitRange: .lsbMsb(.init(lsb: 2, msb: 3)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "Count_UP",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "Count_DOWN",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
        .init(
          name: "Toggle",
          data: .value(.init(value: .init(value: 2, mask: previewMask)))),
      ])),
  .init(
    name: "RST",
    bitRange: .lsbMsb(.init(lsb: 1, msb: 1)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "Reserved",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "Reset_Timer",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
      ])),
  .init(
    name: "EN",
    bitRange: .lsbMsb(.init(lsb: 0, msb: 0)),
    enumeratedValues: .init(
      enumeratedValue: [
        .init(
          name: "Disable",
          data: .value(.init(value: .init(value: 0, mask: previewMask)))),
        .init(
          name: "Enable",
          data: .value(.init(value: .init(value: 1, mask: previewMask)))),
      ])),
]

package let previewRegister = SVDRegister(
  name: "TestRegister3",
  addressOffset: 0x12,
  registerProperties: .init(
    size: 48,
    access: nil,
    protection: nil,
    resetValue: 0xabcd,
    resetMask: 0x1234),
  fields: .init(field: previewFields))


