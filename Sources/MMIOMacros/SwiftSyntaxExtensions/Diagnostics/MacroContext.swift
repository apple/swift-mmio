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
import SwiftSyntaxMacros

struct MacroContext<Macro, Context>
where Macro: ParsableMacro, Context: MacroExpansionContext {
  var context: Context

  init(_: Macro.Type = Macro.self, _ context: Context) {
    self.context = context
  }

  func error(
    at node: some SyntaxProtocol,
    message: ErrorDiagnostic<Macro>,
    highlights: [Syntax]? = nil,
    notes: [Note] = [],
    fixIts: FixIt...
  ) {
    self.context.diagnose(
      .init(
        node: node,
        position: nil,
        message: message,
        highlights: highlights,
        notes: notes,
        fixIts: fixIts))
  }
}

extension MacroContext where Context == SuppressionContext {
  static func makeSuppressingDiagnostics(
    _: Macro.Type = Macro.self
  ) -> MacroContext<Macro, SuppressionContext> {
    self.init(Macro.self, SuppressionContext())
  }
}

extension MacroContext {
  func makeSuppressingDiagnostics() -> MacroContext<Macro, SuppressionContext> {
    .init(Macro.self, .init())
  }
}

class SuppressionContext: MacroExpansionContext {
  func location(
    of node: some SyntaxProtocol,
    at position: PositionInSyntaxNode,
    filePathMode: SourceLocationFilePathMode
  ) -> SwiftSyntaxMacros.AbstractSourceLocation? {
    nil
  }

  func makeUniqueName(_ name: String) -> TokenSyntax {
    fatalError("Unsupported")
  }

  func diagnose(_ diagnostic: SwiftDiagnostics.Diagnostic) {
    // ignore
  }
}
