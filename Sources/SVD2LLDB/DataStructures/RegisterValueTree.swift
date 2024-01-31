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

final class ValueTree {
  enum Value {
    case data(UInt64, UInt64)
    case skipped
    case error
  }

  var name: String
  var value: Value?
  var children: [ValueTree]

  init(name: String, value: Value?, children: [ValueTree]) {
    self.name = name
    self.value = value
    self.children = children
  }
}

extension ValueTree {
  static func container(name: String) -> Self {
    .init(name: name, value: nil, children: [])
  }

  func child(name: String) -> ValueTree? {
    self.children.first { $0.name == name }
  }
}

extension ValueTree: CustomStringConvertible {
  var description: String {
    self._description(prefix: "")
  }

  func _description(prefix: String) -> String {
    var description = ""
    description.append("\(prefix)\(self.name):")
    if let value = self.value {
      description.append(" \(value)")
    }
    description.append("\n")
    for child in self.children {
      description.append(child._description(prefix: prefix.appending("  ")))
    }
    return description
  }
}

extension ValueTree.Value: CustomStringConvertible {
  var description: String {
    switch self {
    case .data(let value, let bits): "\(hex: value, bits: bits)"
    case .skipped: "<skipped>"
    case .error: "<error>"
    }
  }
}
