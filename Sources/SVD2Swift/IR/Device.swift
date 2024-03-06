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

struct Vector {
  var stride: UInt64
  var count: UInt64
}

struct Device {
  var name: String
  var description: String
  var peripherals: [Peripheral]
}

struct Peripheral {
  var name: String
  var derivedFrom: String?
  var description: String
  var baseAddress: UInt64
  var vector: Optional<Vector>
  var registers: [Register]?
  var interrupt: Interrupt?
}

struct Register {
  var name: String
  var description: String
  var addressOffset: UInt64
  var vector: Optional<Vector>
  var size: UInt64
  var resetValue: UInt64
  var fields: [Field]
}

struct Field {
  var name: String
  var description: String
  var vector: Optional<Vector>
  var lsb: UInt64
  var msb: UInt64
  var access: FieldAccess
}

enum FieldAccess {
  case readOnly
  case writeOnly
  case readWrite
}

struct Interrupt {
  var name: String
  var description: String
  var value: UInt64
}
