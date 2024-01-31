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

import SVD

protocol SVDItem {
  var addressOffset: UInt64 { get }
  var name: String { get }
  var readAction: SVDReadAction? { get }
  var modifiedWriteValues: SVDModifiedWriteValues? { get }
  var registerProperties: SVDRegisterProperties { get }

  // FIXME: This copies the entire subtree
  func children() -> [any SVDItem]
  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)]
}

extension SVDItem {
  func child(at key: some StringProtocol) -> (any SVDItem)? {
    self.children().first { $0.name.matches(key) }
  }

  func child(at keyPath: ArraySlice<Substring>) -> (any SVDItem)? {
    var keyPath = keyPath
    var item: any SVDItem = self
    while let key = keyPath.first {
      defer { keyPath.removeFirst() }
      guard let _item = item.child(at: key) else { return nil }
      item = _item
    }
    return item
  }
}

extension SVDDevice: SVDItem {
  var addressOffset: UInt64 { 0 }
  var readAction: SVDReadAction? { nil }
  var modifiedWriteValues: SVD.SVDModifiedWriteValues? { nil }

  func children() -> [any SVDItem] { self.peripherals.peripheral }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info = [(String, String)]()
    if let vendor { info.append(("Vendor", "\(vendor)")) }
    if let vendorID { info.append(("Vendor ID", "\(vendorID)")) }
    if let series { info.append(("Series", "\(series)")) }
    if let version { info.append(("Version", "\(version)")) }
    if let description { info.append(("Description", "\(description)")) }
    if let cpu { info.append(("CPU", "\(cpu.name)")) }
    info.append(("Address Bit Alignment", "\(self.addressUnitBits)"))
    info.append(("Single Transfer Width", "\(self.width)"))
    if !self.peripherals.peripheral.isEmpty {
      let description = self.peripherals.peripheral
        .lazy.map(\.name).joined(separator: ", ")
      info.append(("Peripherals", "[\(description)]"))
    }
    return info
  }
}

extension SVDPeripheral: SVDItem {
  var addressOffset: UInt64 { self.baseAddress }
  var readAction: SVDReadAction? { nil }
  var modifiedWriteValues: SVD.SVDModifiedWriteValues? { nil }

  func children() -> [any SVDItem] {
    (self.registers?.cluster ?? []) + (self.registers?.register ?? [])
  }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info = [(String, String)]()
    if let version { info.append(("Version", "\(version)")) }
    if let description { info.append(("Description", "\(description)")) }
    info.append(("Address", "\(hex: address)"))
    if let interrupt = self.interrupt {
      info.append(("Interrupt Name", "\(interrupt.name)"))
      if let description = interrupt.description {
        info.append(("Interrupt Description", "\(description)"))
      }
      info.append(("Interrupt Value", "\(interrupt.value)"))
    }
    if let registers = self.registers {
      if !registers.cluster.isEmpty {
        let description = registers.cluster
          .lazy.map(\.name).joined(separator: ", ")
        info.append(("Clusters", "[\(description)]"))
      }
      if !registers.register.isEmpty {
        let description = registers.register
          .lazy.map(\.name).joined(separator: ", ")
        info.append(("Registers", "[\(description)]"))
      }
    }
    return info
  }
}

extension SVDCluster: SVDItem {
  var readAction: SVDReadAction? { nil }
  var modifiedWriteValues: SVD.SVDModifiedWriteValues? { nil }

  func children() -> [any SVDItem] {
    (self.cluster ?? []) + (self.register ?? [])
  }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info = [(String, String)]()
    info.append(("Description", "\(description)"))
    info.append(("Address", "\(hex: address)"))
    if let cluster = self.cluster {
      if !cluster.isEmpty {
        let description = cluster.lazy.map(\.name).joined(separator: ", ")
        info.append(("Clusters", "[\(description)]"))
      }
    }
    if let register = self.register {
      if !register.isEmpty {
        let description = register.lazy.map(\.name).joined(separator: ", ")
        info.append(("Registers", "[\(description)]"))
      }
    }
    return info
  }
}

extension SVDRegister: SVDItem {
  var field: [SVDField]? { self.fields?.field }

  func children() -> [any SVDItem] { self.fields?.field ?? [] }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info = [(String, String)]()
    if let description { info.append(("Description", "\(description)")) }
    info.append(("Address", "\(hex: address)"))
    if let size = registerProperties.size {
      info.append(("Bit Width", "\(size)"))
      if let resetValue = registerProperties.resetValue {
        info.append(("Reset Value", "\(hex: resetValue, bits: size)"))
      }
      if let resetMask = registerProperties.resetMask {
        info.append(("Reset Mask", "\(hex: resetMask, bits: size)"))
      }
    }
    if let protection = registerProperties.protection {
      info.append(("Protection", "\(protection)"))
    }
    if let dataType = self.dataType { info.append(("Data Type", "\(dataType)")) }
    if let modifiedWriteValues = self.modifiedWriteValues {
      info.append(("Modified Write Values", "\(modifiedWriteValues)"))
    }
    if let writeConstraint = self.writeConstraint { info.append(("Write Constraint", "\(writeConstraint)")) }
    if let readAction = self.readAction { info.append(("Read Action", "\(readAction)")) }
    if let fields = self.fields, !fields.field.isEmpty {
      let description = fields.field.lazy.map(\.name).joined(separator: ", ")
      info.append(("Fields", "[\(description)]"))
    }
    return info
  }
}

extension SVDField: SVDItem {
  var addressOffset: UInt64 { 0 }
  var registerProperties: SVDRegisterProperties { .none }

  func children() -> [any SVDItem] { [] }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info = [(String, String)]()
    if let description { info.append(("Description", "\(description)")) }
    let range = self.bitRange.range
    info.append(("Bit Range", "[\(range.upperBound - 1):\(range.lowerBound)]"))
    if let access = self.access { info.append(("Access", "\(access)")) }
    if let modifiedWriteValues = self.modifiedWriteValues {
      info.append(("Modified Write Values", "\(modifiedWriteValues)"))
    }
    if let writeConstraint = self.writeConstraint { info.append(("Write Constraint", "\(writeConstraint)")) }
    if let readAction = self.readAction { info.append(("Read Action", "\(readAction)")) }
    return info
  }
}
