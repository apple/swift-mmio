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

import SwiftSyntax

extension WithAttributesSyntax {
  func hasAttribute(_ baseName: String) -> Bool {
    for attribute in self.attributes {
      guard case .attribute(let attribute) = attribute else {
        // Ignore `#if` conditional attributes
        // FIXME: diagnostic?
        continue
      }
      let name = attribute.attributeName
      guard let identifier = name.as(IdentifierTypeSyntax.self) else {
        // FIXME: maybe need to support MemberTypeSyntax?
        continue
      }
      if identifier.name.text == baseName { return true }
    }
    return false
  }

  func hasAttribute<T>(oneOf baseNames: [T]) -> (AttributeSyntax, T)? where T: RawRepresentable, T.RawValue == String {
    let baseNames = Dictionary(uniqueKeysWithValues: baseNames.map { ($0.rawValue, $0) })
    var matches = [(AttributeSyntax, T)]()
    for attribute in self.attributes {
      guard case .attribute(let attribute) = attribute else {
        // Ignore `#if` conditional attributes
        // FIXME: diagnostic?
        continue
      }
      let name = attribute.attributeName
      guard let identifier = name.as(IdentifierTypeSyntax.self) else {
        // FIXME: maybe need to support MemberTypeSyntax?
        continue
      }
      if let value = baseNames[identifier.name.text] {
        matches.append((attribute, value))
      }
    }
    guard matches.count == 1 else { return nil }
    return matches[0]
  }
}
