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

extension WithModifiersSyntax {
  var accessLevel: DeclModifierSyntax? {
    self.modifiers
      .lazy
      .filter {
        switch $0.name.tokenKind {
        case .keyword(.open),
          .keyword(.public),
          .keyword(.package),
          .keyword(.internal),
          .keyword(.fileprivate),
          .keyword(.private):
          true
        default:
          false
        }
      }
      .first
  }
}
