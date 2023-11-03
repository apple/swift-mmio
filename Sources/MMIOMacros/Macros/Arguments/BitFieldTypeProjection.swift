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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

struct BitFieldTypeProjection {
  var expression: ExprSyntax
}

extension BitFieldTypeProjection: Equatable {}

extension BitFieldTypeProjection: ExpressibleByExprSyntax {
  init(
    expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    guard
      let memberAccess = expression.as(MemberAccessExprSyntax.self),
      let base = memberAccess.base,
      memberAccess.declName.baseName.tokenKind == .keyword(.`self`)
    else {
      context.error(
        at: expression,
        message: .expectedTypeReferenceLiteral(),
        fixIts: .replaceExpressionWithTypeReference(node: expression))
      throw ExpansionError()
    }
    self.expression = base
  }
}

extension ErrorDiagnostic {
  static func expectedTypeReferenceLiteral() -> Self {
    .init("'\(Macro.signature)' requires literal type reference")
  }
}

extension FixIt {
  static func replaceExpressionWithTypeReference(
    node: ExprSyntax
  ) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Replace with expression with literal type reference"),
      oldNode: node,
      newNode: EditorPlaceholderDeclSyntax(
        placeholder: .identifier("<#Type#>.self")))
  }
}
