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

struct SVDKeyPathComponent {
  var kind: SVDItemKind
  var name: String
}

extension SVDKeyPathComponent {
  static func device(_ name: String) -> Self {
    self.init(kind: .device, name: name)
  }

  static func peripheral(_ name: String) -> Self {
    self.init(kind: .peripheral, name: name)
  }

  static func cluster(_ name: String) -> Self {
    self.init(kind: .cluster, name: name)
  }

  static func register(_ name: String) -> Self {
    self.init(kind: .register, name: name)
  }

  static func field(_ name: String) -> Self {
    self.init(kind: .field, name: name)
  }
}

extension SVDKeyPathComponent: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool { lhs.name < rhs.name }
}

extension SVDKeyPathComponent: CustomStringConvertible {
  var description: String {
    "<\(self.kind): \(self.name)>"
  }
}

extension SVDKeyPathComponent: Decodable {}

extension SVDKeyPathComponent: Encodable {}

extension SVDKeyPathComponent: Equatable {}

extension SVDKeyPathComponent: Hashable {}
