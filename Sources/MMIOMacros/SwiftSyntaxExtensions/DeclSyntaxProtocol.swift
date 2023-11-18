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

protocol DiagnosableDeclSyntaxProtocol: DeclSyntaxProtocol {
  static var declTypeName: String { get }
  var introducerKeyword: TokenSyntax { get }
}

extension AccessorDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "accessor"
  var introducerKeyword: TokenSyntax { self.accessorSpecifier }
}

extension ActorDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "actor"
  var introducerKeyword: TokenSyntax { self.actorKeyword }
}

extension AssociatedTypeDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "associated type"
  var introducerKeyword: TokenSyntax { self.associatedtypeKeyword }
}

extension ClassDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "class"
  var introducerKeyword: TokenSyntax { self.classKeyword }
}

extension DeinitializerDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "deinitializer"
  var introducerKeyword: TokenSyntax { self.deinitKeyword }
}

extension EditorPlaceholderDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "editor placeholder"
  var introducerKeyword: TokenSyntax { self.placeholder }
}

extension EnumCaseDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "enum case"
  var introducerKeyword: TokenSyntax { self.caseKeyword }
}

extension EnumDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "enum case"
  var introducerKeyword: TokenSyntax { self.enumKeyword }
}

extension ExtensionDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "extension"
  var introducerKeyword: TokenSyntax { self.extensionKeyword }
}

extension FunctionDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "function"
  var introducerKeyword: TokenSyntax { self.funcKeyword }
}

extension IfConfigDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "if config"
  var introducerKeyword: TokenSyntax {
    self.clauses.first?.poundKeyword ?? .poundToken()
  }
}

extension ImportDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "import"
  var introducerKeyword: TokenSyntax { self.importKeyword }
}

extension InitializerDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "initializer"
  var introducerKeyword: TokenSyntax { self.initKeyword }
}

extension MacroDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "macro"
  var introducerKeyword: TokenSyntax { self.macroKeyword }
}

extension MacroExpansionDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "macro expansion"
  var introducerKeyword: TokenSyntax { self.macroName }
}

extension MissingDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "missing"
  var introducerKeyword: TokenSyntax { self.placeholder }
}

extension OperatorDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "operator"
  var introducerKeyword: TokenSyntax { self.operatorKeyword }
}

extension PoundSourceLocationSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "pound source location"
  var introducerKeyword: TokenSyntax { self.poundSourceLocation }
}

extension PrecedenceGroupDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "precedence group"
  var introducerKeyword: TokenSyntax { self.precedencegroupKeyword }
}

extension ProtocolDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "protocol"
  var introducerKeyword: TokenSyntax { self.protocolKeyword }
}

extension StructDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static let declTypeName = "struct"
  var introducerKeyword: TokenSyntax { self.structKeyword }
}

extension SubscriptDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "subscript"
  var introducerKeyword: TokenSyntax { self.subscriptKeyword }
}

extension TypeAliasDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "type alias"
  var introducerKeyword: TokenSyntax { self.typealiasKeyword }
}

extension VariableDeclSyntax: DiagnosableDeclSyntaxProtocol {
  static var declTypeName = "variable"
  var introducerKeyword: TokenSyntax { self.bindingSpecifier }
}

extension DeclSyntaxProtocol {
  func requireAs<Other>(
    _ other: Other.Type,
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> Other where Other: DiagnosableDeclSyntaxProtocol {
    if let decl = self.as(Other.self) { return decl }

    let node: any SyntaxProtocol =
      (self as? DiagnosableDeclSyntaxProtocol)?.introducerKeyword ?? self

    throw context.error(
      at: node,
      message: .expectedDecl(Other.self))
  }
}

extension ErrorDiagnostic {
  static func expectedDecl(_ decl: DiagnosableDeclSyntaxProtocol.Type) -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to \(decl.declTypeName) \
      declarations
      """)
  }
}
