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
import SwiftSyntaxMacros

protocol DiagnosableDeclGroupSyntax: DeclGroupSyntax {
  static var declTypeName: String { get }
  var introducerKeyword: TokenSyntax { get }
}

extension ActorDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "actor"
  var introducerKeyword: TokenSyntax { self.actorKeyword }
}
extension ClassDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "class"
  var introducerKeyword: TokenSyntax { self.classKeyword }
}
extension EnumDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "enum"
  var introducerKeyword: TokenSyntax { self.enumKeyword }
}
extension ExtensionDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "extension"
  var introducerKeyword: TokenSyntax { self.extensionKeyword }
}
extension ProtocolDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "protocol"
  var introducerKeyword: TokenSyntax { self.protocolKeyword }
}
extension StructDeclSyntax: DiagnosableDeclGroupSyntax {
  static let declTypeName = "struct"
  var introducerKeyword: TokenSyntax { self.structKeyword }
}

extension DeclGroupSyntax {
  func requireAs<Other>(
    _ other: Other.Type,
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> Other where Other: DiagnosableDeclGroupSyntax {
    if let decl = self.as(Other.self) { return decl }

    let node: any SyntaxProtocol =
      (self as? DiagnosableDeclGroupSyntax)?.introducerKeyword ?? self

    context.error(
      at: node,
      message: .expectedDecl(Other.self))

    throw ExpansionError()
  }
}
