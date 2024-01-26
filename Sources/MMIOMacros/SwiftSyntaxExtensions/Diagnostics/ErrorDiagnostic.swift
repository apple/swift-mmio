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
}

//// FIXME: remove this after upgrading to swift-syntax 5.10
///// The message of a note that is specified by a string literal
/////
///// This type allows macro authors to quickly generate note messages based on
///// a string. For any non-trivial note messages, it is encouraged to define a
///// custom type that conforms to `NoteMessage`.
//struct MacroExpansionNoteMessage: NoteMessage {
//  var message: String
//
//  var fixItID: SwiftDiagnostics.MessageID { self.noteID }
//  var noteID: SwiftDiagnostics.MessageID {
//    .init(domain: "SwiftSyntaxMacros", id: "\(Self.self)")
//  }
//
//  init(_ message: String) {
//    self.message = message
//  }
//}
