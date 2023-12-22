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

extension PatternBindingSyntax {
  func requireSimpleBindingIdentifier(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> IdentifierPatternSyntax {
    guard let pattern = self.pattern.as(IdentifierPatternSyntax.self) else {
      throw context.error(
        at: self.pattern,
        message: .unexpectedBindingIdentifier())
    }
    return pattern
  }

  func requireSimpleTypeIdentifier(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> TypeSyntax {
    guard let type = self.typeAnnotation?.type else {
      throw context.error(
        at: self,
        message: .unexpectedBindingType(),
        fixIts: .insertBindingType(node: self))
    }

    if let typeIdentifier = type.as(IdentifierTypeSyntax.self) {
      // Binding type must not be "_" (implicitly typed).
      guard typeIdentifier.name.tokenKind != .wildcard else {
        throw context.error(
          at: type,
          message: .unexpectedBindingType(),
          fixIts: .insertBindingType(node: self))
      }
      // Ok
    } else if type.is(MemberTypeSyntax.self) {
      // Ok
    } else {
      throw context.error(
        at: type,
        message: .unexpectedBindingType())
    }

    return type
  }

  func requireNoAccessor(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    if let accessorBlock = self.accessorBlock {
      throw context.error(
        at: accessorBlock,
        message: .expectedStoredProperty(),
        fixIts: .removeAccessorBlock(node: self))
    }
  }
}

// FIXME: Improve diagnostics, what are "simple types/identifiers"?
extension ErrorDiagnostic {
  static func unexpectedBindingIdentifier() -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to properties with simple
      identifiers
      """)
  }

  static func unexpectedBindingType() -> Self {
    .init(
      """
      '\(Macro.signature)' can only be applied to properties with simple types
      """)
  }

  static func expectedStoredProperty() -> Self {
    .init("'\(Macro.signature)' can only be applied to stored properties")
  }
}

extension FixIt {
  static func insertBindingType(node: PatternBindingSyntax) -> FixIt {
    // FIXME: https://github.com/apple/swift-syntax/issues/2205
    .replace(
      message: MacroExpansionFixItMessage(
        "Insert explicit type annotation"),
      oldNode: node,
      newNode: node.with(
        \.typeAnnotation,
        .init(
          EditorPlaceholderDeclSyntax(
            placeholder: .identifier("<#Type#>")))))
  }

  static func removeAccessorBlock(node: PatternBindingSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Remove accessor block"),
      oldNode: node,
      newNode: node.with(\.accessorBlock, nil))
  }
}
