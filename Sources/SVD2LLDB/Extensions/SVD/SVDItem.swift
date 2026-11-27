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

import Foundation
import MMIOUtilities
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
    var info: [(String, String)] = []
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
    (self.registers?.cluster ?? []).flatMap { $0.expandingDimensions() }
      + (self.registers?.register ?? []).flatMap { $0.expandingDimensions() }
  }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info: [(String, String)] = []
    if let version { info.append(("Version", "\(version)")) }
    if let description { info.append(("Description", "\(description)")) }
    info.append(("Address", "\(hex: address)"))
    for interrupt in self.interrupt ?? [] {
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
    (self.cluster ?? []).flatMap { $0.expandingDimensions() }
      + (self.register ?? []).flatMap { $0.expandingDimensions() }
  }

  func info(
    registerProperties: SVDRegisterProperties,
    address: UInt64
  ) -> [(String, String)] {
    var info: [(String, String)] = []
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
    var info: [(String, String)] = []
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
    if let dataType = self.dataType {
      info.append(("Data Type", "\(dataType)"))
    }
    if let modifiedWriteValues = self.modifiedWriteValues {
      info.append(("Modified Write Values", "\(modifiedWriteValues)"))
    }
    if let writeConstraint = self.writeConstraint {
      info.append(("Write Constraint", "\(writeConstraint)"))
    }
    if let readAction = self.readAction {
      info.append(("Read Action", "\(readAction)"))
    }
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
    var info: [(String, String)] = []
    if let description { info.append(("Description", "\(description)")) }
    let range = self.bitRange.range
    info.append(("Bit Range", "[\(range.upperBound - 1):\(range.lowerBound)]"))
    if let access = self.access { info.append(("Access", "\(access)")) }
    if let modifiedWriteValues = self.modifiedWriteValues {
      info.append(("Modified Write Values", "\(modifiedWriteValues)"))
    }
    if let writeConstraint = self.writeConstraint {
      info.append(("Write Constraint", "\(writeConstraint)"))
    }
    if let readAction = self.readAction {
      info.append(("Read Action", "\(readAction)"))
    }
    return info
  }
}

/// An SVD element that can be declared once and repeated with `<dim>`.
protocol SVDDimensionable {
  var name: String { get set }
  var addressOffset: UInt64 { get set }
  var dimensionElement: SVDDimensionElement? { get set }
}

extension SVDRegister: SVDDimensionable {}
extension SVDCluster: SVDDimensionable {}

extension SVDDimensionable {
  /// Expands an array declared with `<dim>` into one element per index.
  ///
  /// Each element has the `%s` (or `[%s]`) placeholder in its name replaced by
  /// its index and its address offset advanced by `<dimIncrement>`. An element
  /// without `<dim>` is returned unchanged.
  func expandingDimensions() -> [Self] {
    guard let dimensionElement = self.dimensionElement else { return [self] }
    let indices = dimensionElement.indices()
    return indices.enumerated().map { position, index in
      var copy = self
      copy.name =
        self.name
        .replacingOccurrences(of: "[%s]", with: index)
        .replacingOccurrences(of: "%s", with: index)
      copy.addressOffset =
        self.addressOffset
        &+ UInt64(position) &* dimensionElement.dimIncrement
      copy.dimensionElement = nil
      return copy
    }
  }
}

extension SVDDimensionElement {
  /// The index names of the array, taken from `<dimIndex>`.
  ///
  /// `<dimIndex>` is either a range such as `0-3` or a comma separated list
  /// such as `A,B,C`. Without it the indices are `0..<dim`. A list whose length
  /// differs from `<dim>` is not trusted and falls back to `0..<dim`.
  func indices() -> [String] {
    let count = Int(clamping: self.dim)
    let fallback = (0..<count).map(String.init)
    guard let dimIndex = self.dimIndex?.trimmingCharacters(in: .whitespaces),
      !dimIndex.isEmpty
    else { return fallback }

    let parts = dimIndex.split(separator: "-", omittingEmptySubsequences: false)
    if parts.count == 2,
      let lower = Int(parts[0].trimmingCharacters(in: .whitespaces)),
      let upper = Int(parts[1].trimmingCharacters(in: .whitespaces)),
      lower <= upper
    {
      guard upper - lower + 1 == count else { return fallback }
      return (lower...upper).map(String.init)
    }

    let list = dimIndex.split(separator: ",").map {
      $0.trimmingCharacters(in: .whitespaces)
    }
    return list.count == count ? list : fallback
  }
}
