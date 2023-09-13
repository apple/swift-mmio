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

protocol HasModifiersDeclSyntax {
  var modifiers: DeclModifierListSyntax { get }
}

// extension AccessorDeclSyntax: HasModifiersDeclSyntax {}
extension ActorDeclSyntax: HasModifiersDeclSyntax {}
extension AssociatedTypeDeclSyntax: HasModifiersDeclSyntax {}
extension ClassDeclSyntax: HasModifiersDeclSyntax {}
extension DeinitializerDeclSyntax: HasModifiersDeclSyntax {}
extension EditorPlaceholderDeclSyntax: HasModifiersDeclSyntax {}
extension EnumCaseDeclSyntax: HasModifiersDeclSyntax {}
extension EnumDeclSyntax: HasModifiersDeclSyntax {}
extension ExtensionDeclSyntax: HasModifiersDeclSyntax {}
extension FunctionDeclSyntax: HasModifiersDeclSyntax {}
// extension IfConfigDeclSyntax: HasModifiersDeclSyntax {}
extension ImportDeclSyntax: HasModifiersDeclSyntax {}
extension InitializerDeclSyntax: HasModifiersDeclSyntax {}
extension MacroDeclSyntax: HasModifiersDeclSyntax {}
extension MacroExpansionDeclSyntax: HasModifiersDeclSyntax {}
extension MissingDeclSyntax: HasModifiersDeclSyntax {}
// extension OperatorDeclSyntax: HasModifiersDeclSyntax {}
// extension PoundSourceLocationSyntax: HasModifiersDeclSyntax {}
extension PrecedenceGroupDeclSyntax: HasModifiersDeclSyntax {}
extension ProtocolDeclSyntax: HasModifiersDeclSyntax {}
extension StructDeclSyntax: HasModifiersDeclSyntax {}
extension SubscriptDeclSyntax: HasModifiersDeclSyntax {}
extension TypeAliasDeclSyntax: HasModifiersDeclSyntax {}
extension VariableDeclSyntax: HasModifiersDeclSyntax {}
