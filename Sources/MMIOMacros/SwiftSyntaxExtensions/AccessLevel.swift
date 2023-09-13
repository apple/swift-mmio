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
import SwiftSyntaxBuilder

enum AccessLevel: String {
  case `open`
  case `public`
  case `package`
  case `internal`
  case `fileprivate`
  case `private`
}

extension AccessLevel: CaseIterable {}

extension HasModifiersDeclSyntax {
  var accessLevel: AccessLevel? {
    self.modifiers
      .lazy
      .compactMap { AccessLevel(rawValue: $0.name.text) }
      .first
  }
}

extension SyntaxStringInterpolation {
  mutating func appendInterpolation(_ accessLevel: AccessLevel?) {
    self.appendInterpolation(raw: accessLevel?.rawValue ?? "")
  }
}
