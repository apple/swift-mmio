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

//import SVD
//
//struct SVDLookupItemNotFoundError: Error {
//  var parentName: String
//  var childName: String
//}
//
//extension SVDDocument {
//  func item(at keyPath: SVDKeyPath) throws -> SVDItem {
//    try self.item(at: keyPath.components[...])
//  }
//
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    guard !keyPath.isEmpty else {
//      throw SVDLookupItemNotFoundError(parentName: "<root>", childName: "<none>")
//    }
//    let key = keyPath.removeFirst()
//    if key.kind == .device, self.device.name == key.name {
//      return try self.device.item(at: keyPath)
//    } else {
//      throw SVDLookupItemNotFoundError(parentName: "<root>", childName: key.name)
//    }
//  }
//}
//
//extension SVDDevice {
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    if keyPath.isEmpty { return .device(self) }
//    let key = keyPath.removeFirst()
//    if key.kind == .peripheral, let item = self.peripherals.peripheral.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else {
//      throw SVDLookupItemNotFoundError(parentName: self.name, childName: key.name)
//    }
//  }
//}
//
//extension SVDPeripheral {
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    if keyPath.isEmpty { return .peripheral(self) }
//    let key = keyPath.removeFirst()
//    if key.kind == .cluster, let item = self.registers?.cluster.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else if key.kind == .register, let item = self.registers?.register.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else {
//      throw SVDLookupItemNotFoundError(parentName: self.name, childName: key.name)
//    }
//  }
//}
//
//extension SVDCluster {
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    if keyPath.isEmpty { return .cluster(self) }
//    let key = keyPath.removeFirst()
//    if key.kind == .cluster, let item = self.cluster?.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else if key.kind == .register, let item = self.register?.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else {
//      throw SVDLookupItemNotFoundError(parentName: self.name, childName: key.name)
//    }
//  }
//}
//
//extension SVDRegister {
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    if keyPath.isEmpty { return .register(self) }
//    let key = keyPath.removeFirst()
//    if key.kind == .field, let item = self.fields?.field.first(where: { $0.name == key.name }) {
//      return try item.item(at: keyPath)
//    } else {
//      throw SVDLookupItemNotFoundError(parentName: self.name, childName: key.name)
//    }
//  }
//}
//
//extension SVDField {
//  func item(
//    at keyPath: ArraySlice<SVDKeyPathComponent>
//  ) throws -> SVDItem {
//    var keyPath = keyPath
//    if keyPath.isEmpty { return .field(self) }
//    let key = keyPath.removeFirst()
//    throw SVDLookupItemNotFoundError(parentName: self.name, childName: key.name)
//  }
//}
