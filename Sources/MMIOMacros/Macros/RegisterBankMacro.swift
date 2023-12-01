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
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct RegisterBankMacro {}

extension RegisterBankMacro: Sendable {}

extension RegisterBankMacro: ParsableMacro {
  mutating func update(
    label: String,
    from expression: ExprSyntax,
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws {
    fatalError()
  }
}

extension RegisterBankMacro: MMIOMemberMacro {
  static var memberMacroSuppressParsingDiagnostics: Bool = false

  func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: MacroContext<Self, some MacroExpansionContext>
  ) throws -> [DeclSyntax] {
    // Can only applied to structs.
    // FIXME: https://github.com/apple/swift-syntax/pull/2366
    // swift-format-ignore: NeverForceUnwrap
    let declaration = declaration as! DeclSyntaxProtocol
    let structDecl = try declaration.requireAs(StructDeclSyntax.self, context)

    // Retrieve the access level of the struct, so we can use the same
    // access level for the unsafeAddress property and initializer.
    let acl = structDecl.accessLevel

    return [
      "\(acl)private(set) var unsafeAddress: UInt",
      """
      #if FEATURE_INTERPOSABLE
      var interposer: (any MMIOInterposer)?
      #endif
      """,
      """
      #if FEATURE_INTERPOSABLE
      @inlinable @inline(__always)
      \(acl)init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
        self.unsafeAddress = unsafeAddress
        self.interposer = interposer
      }
      #else
      @inlinable @inline(__always)
      \(acl)init(unsafeAddress: UInt) {
        self.unsafeAddress = unsafeAddress
      }
      #endif
      """,
    ]
  }
}
