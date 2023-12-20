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

struct ErrorDiagnostic<Macro> where Macro: ParsableMacro {
  var diagnosticID: MessageID
  var severity = DiagnosticSeverity.error
  var message: String

  init(_ message: String, id: StaticString = #function) {
    self.diagnosticID = .init(domain: "MMIO", id: "\(id)")
    self.message = message
  }
}

extension ErrorDiagnostic: DiagnosticMessage {}

extension ErrorDiagnostic {
  static var internalErrorSuffix: String {
    """
    Please file an issue at \
    https://github.com/apple/swift-mmio/issues and, if possible, attach \
    the source code that triggered the issue
    """
  }

  static func internalError() -> Self {
    .init("'\(Macro.signature)' internal error. \(Self.internalErrorSuffix)")
  }

  // Declaration Member Errors
  static func onlyMemberVarDecls() -> Self {
    .init("'\(Macro.signature)' type can only contain properties")
  }

  // Binding Identifier Errors
  static func expectedBindingIdentifier() -> Self {
    .init("'\(Macro.signature)' cannot be applied to anonymous properties")
  }

  static func unexpectedTupleBindingIdentifier() -> Self {
    .init("'\(Macro.signature)' cannot be applied to tuple properties")
  }

  // Binding Type Errors
  static func expectedTypeAnnotation() -> Self {
    .init("'\(Macro.signature)' cannot be applied to untyped properties")
  }

  static func unexpectedInferredType() -> Self {
    .init(
      """
      '\(Macro.signature)' cannot be applied to implicitly typed properties
      """)
  }

  // FIXME: Improve diagnostic, what is a "simple type"?
  static func unexpectedBindingType() -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to properties with simple types
      """)
  }

  static func expectedStoredProperty() -> Self {
    .init("'\(Macro.signature)' cannot be applied properties with accessors")
  }
}
