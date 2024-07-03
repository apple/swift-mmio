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

struct SVDKeyPath {
  var components: [SVDKeyPathComponent]
}

extension SVDKeyPath {
  mutating func append(_ component: SVDKeyPathComponent) {
    self.components.append(component)
  }

  func appending(_ component: SVDKeyPathComponent) -> Self {
    var copy = self
    copy.append(component)
    return copy
  }
}

extension SVDKeyPath {
  static let empty = Self(components: [])
}

extension SVDKeyPath: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    for (lhs, rhs) in zip(lhs.components, rhs.components) {
      if lhs != rhs { return lhs < rhs }
    }
    return lhs.components.count < rhs.components.count
  }
}

extension SVDKeyPath: CustomStringConvertible {
  var description: String {
    if self.components.isEmpty {
      "<root>"
    } else {
      self.components.lazy.map(\.description).joined(separator: ".")
    }
  }
}

extension SVDKeyPath: Decodable {}

extension SVDKeyPath: Encodable {}

extension SVDKeyPath: Equatable {}

extension SVDKeyPath: Hashable {}

extension SVDKeyPath: Identifiable { var id: Self { self } }
