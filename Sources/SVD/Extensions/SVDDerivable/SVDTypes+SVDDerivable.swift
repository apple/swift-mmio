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

import MMIOUtilities

extension SVDPeripheral: SVDDerivable {
  static let kind = "Peripheral"

  mutating func merging(_ other: Self) {
    self.derivedFrom ??= other.derivedFrom
    self.version ??= other.version
    self.description ??= other.description
    self.alternatePeripheral ??= other.alternatePeripheral
    self.groupName ??= other.groupName
    self.prependToName ??= other.prependToName
    self.appendToName ??= other.appendToName
    self.headerStructName ??= other.headerStructName
    self.disableCondition ??= other.disableCondition
    self.addressBlock ??= other.addressBlock
    self.interrupt ??= other.interrupt
    self.registers ??= other.registers
  }
}

extension SVDCluster: SVDDerivable {
  static let kind = "Cluster"

  mutating func merging(_ other: Self) {
    self.alternateCluster ??= other.alternateCluster
    self.headerStructName ??= other.headerStructName
    self.cluster ??= other.cluster
    self.register ??= other.register
  }
}

extension SVDRegister: SVDDerivable {
  static let kind = "Register"

  mutating func merging(_ other: Self) {
    self.displayName ??= other.displayName
    self.description ??= other.description
    self.alternateGroup ??= other.alternateGroup
    self.alternateRegister ??= other.alternateRegister
    self.dataType ??= other.dataType
    self.modifiedWriteValues ??= other.modifiedWriteValues
    self.writeConstraint ??= other.writeConstraint
    self.readAction ??= other.readAction
    self.fields ??= other.fields
  }
}

extension SVDField: SVDDerivable {
  static let kind = "Field"

  mutating func merging(_ other: Self) {
    self.description ??= other.description
    self.access ??= other.access
    self.modifiedWriteValues ??= other.modifiedWriteValues
    self.writeConstraint ??= other.writeConstraint
    self.readAction ??= other.readAction
    self.enumeratedValues ??= other.enumeratedValues
  }
}
