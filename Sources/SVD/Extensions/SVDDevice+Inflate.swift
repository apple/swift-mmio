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

import MMIOUtilities

// FIXME: Revisit with lazy request-based inflation
extension SVDDevice {
  package mutating func inflate() throws {
    try self.peripherals.peripheral.mutatingForEach { peripheral in
      try peripheral.inflate()
    }
    try self.peripherals.peripheral.deriveElements()
  }
}

extension SVDPeripheral {
  mutating func inflate() throws {
    try self.registers?.cluster.mutatingForEach { cluster in
      try cluster.inflate()
    }
    try self.registers?.cluster.deriveElements()
    try self.registers?.register.mutatingForEach { register in
      try register.inflate()
    }
    try self.registers?.register.deriveElements()
  }
}

extension SVDCluster {
  mutating func inflate() throws {
    try self.cluster?.mutatingForEach { cluster in
      try cluster.inflate()
    }
    try self.cluster?.deriveElements()
    try self.register?.mutatingForEach { register in
      try register.inflate()
    }
    try self.register?.deriveElements()
  }
}

extension SVDRegister {
  mutating func inflate() throws {
    try self.fields?.field.mutatingForEach { field in
      try field.inflate(registerName: self.name)
    }
    try self.fields?.field.deriveElements()
  }
}

extension SVDField {
  mutating func inflate(registerName: String) throws {}
}
