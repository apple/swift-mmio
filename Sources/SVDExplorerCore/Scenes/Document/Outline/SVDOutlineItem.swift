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

struct SVDOutlineItem {
  var keyPath: SVDKeyPath
  var children: [SVDOutlineItem]?

  var name: String { self.keyPath.components.last!.name }
}

extension SVDOutlineItem {
  init(device: SVDDevice, keyPath: SVDKeyPath) {
    self.keyPath = .init(components: [.device(device.name)])
    self.children = device.peripherals.peripheral
      .map { SVDOutlineItem(peripheral: $0, keyPath: self.keyPath) }
      .sorted { $0.name < $1.name }
  }

  init(peripheral: SVDPeripheral, keyPath: SVDKeyPath) {
    self.keyPath = keyPath.appending(.peripheral(peripheral.name))
    var children: [SVDOutlineItem] = []
    if let registers = peripheral.registers?.register {
      let registers =
        registers
        .map { SVDOutlineItem(register: $0, keyPath: self.keyPath) }
        .sorted { $0.name < $1.name }
      children.append(contentsOf: registers)
    }
    if let clusters = peripheral.registers?.cluster {
      let clusters =
        clusters
        .map { SVDOutlineItem(cluster: $0, keyPath: self.keyPath) }
        .sorted { $0.name < $1.name }
      children.append(contentsOf: clusters)
    }
    self.children = children.isEmpty ? nil : children
  }

  init(cluster: SVDCluster, keyPath: SVDKeyPath) {
    self.keyPath = keyPath.appending(.cluster(cluster.name))
    var children: [SVDOutlineItem] = []
    if let registers = cluster.register {
      let registers =
        registers
        .map { SVDOutlineItem(register: $0, keyPath: self.keyPath) }
        .sorted { $0.name < $1.name }
      children.append(contentsOf: registers)
    }
    if let clusters = cluster.cluster {
      let clusters =
        clusters
        .map { SVDOutlineItem(cluster: $0, keyPath: self.keyPath) }
        .sorted { $0.name < $1.name }
      children.append(contentsOf: clusters)
    }
    self.children = children.isEmpty ? nil : children
  }

  init(register: SVDRegister, keyPath: SVDKeyPath) {
    self.keyPath = keyPath.appending(.register(register.name))
    self.children = register.fields?.field
      .map { SVDOutlineItem(field: $0, keyPath: self.keyPath) }
      .sorted { $0.name < $1.name }
  }

  init(field: SVDField, keyPath: SVDKeyPath) {
    self.keyPath = keyPath.appending(.field(field.name))
    self.children = nil
  }
}

extension SVDOutlineItem: Identifiable {
  var id: SVDKeyPath { self.keyPath }
}
