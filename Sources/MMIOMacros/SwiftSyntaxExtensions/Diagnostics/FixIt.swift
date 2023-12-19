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

  static func insertBindingIdentifier(node: PatternSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Insert explicit property identifier"),
      oldNode: node,
      newNode: EditorPlaceholderDeclSyntax(
        placeholder: .identifier("<#Identifier#>")))
  }

  static func removeAccessorBlock(node: PatternBindingSyntax) -> FixIt {
    .replace(
      message: MacroExpansionFixItMessage(
        "Remove accessor block"),
      oldNode: node,
      newNode: node.with(\.accessorBlock, nil))
  }
}
