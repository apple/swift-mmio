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

extension SVDDevice {
  func peripheral(name: some StringProtocol) -> SVDPeripheral? {
    self.peripherals.peripheral.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    guard let item = self.peripheral(name: key) else {
      return nil
    }
    return item.address(
      at: keyPath,
      baseAddress: baseAddress + item.baseAddress)
  }
}

extension SVDPeripheral {
  func cluster(name: some StringProtocol) -> SVDCluster? {
    self.registers?.cluster.first(where: { $0.name.matches(name) })
  }

  func register(name: some StringProtocol) -> SVDRegister? {
    self.registers?.register.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.cluster(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else if let item = self.register(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else {
      return nil
    }
  }
}

extension SVDCluster {
  func cluster(name: some StringProtocol) -> SVDCluster? {
    self.cluster?.first(where: { $0.name.matches(name) })
  }

  func register(name: some StringProtocol) -> SVDRegister? {
    self.register?.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    if let item = self.cluster(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else if let item = self.register(name: key) {
      return item.address(
        at: keyPath,
        baseAddress: baseAddress + item.addressOffset)
    } else {
      return nil
    }
  }
}

extension SVDRegister {
  func field(name: some StringProtocol) -> SVDField? {
    self.fields?.field.first(where: { $0.name.matches(name) })
  }

  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    var keyPath = keyPath
    guard !keyPath.isEmpty else { return baseAddress }
    let key = keyPath.removeFirst()
    guard let item = self.field(name: key) else {
      return nil
    }
    return item.address(
      at: keyPath,
      baseAddress: baseAddress)
  }
}

extension SVDField {
  func address(
    at keyPath: ArraySlice<Substring>,
    baseAddress: UInt64
  ) -> UInt64? {
    guard !keyPath.isEmpty else { return baseAddress }
    return nil
  }
}
