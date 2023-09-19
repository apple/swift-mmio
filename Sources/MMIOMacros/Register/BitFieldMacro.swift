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

enum BitFieldKind: String, CaseIterable {
  case reserved = "Reserved"
  case readWrite = "ReadWrite"
  case readOnly = "ReadOnly"
  case writeOnly = "WriteOnly"
}

extension BitFieldKind {
  var isReadable: Bool {
    switch self {
    case .reserved:
      false
    case .readWrite:
      true
    case .readOnly:
      true
    case .writeOnly:
      false
    }
  }

  var isWriteable: Bool {
    switch self {
    case .reserved:
      false
    case .readWrite:
      true
    case .readOnly:
      false
    case .writeOnly:
      true
    }
  }

  var isSymmetric: Bool {
    switch self {
    case .reserved:
      true
    case .readWrite:
      true
    case .readOnly:
      false
    case .writeOnly:
      false
    }
  }
}

struct BitField {
  var name: IdentifierPatternSyntax
  var type: TypeSyntax
  var kind: BitFieldKind
  var bits: ExprSyntax
  var `as`: ExprSyntax?
}

extension BitFieldMacroArguments {
  init?(kind: BitFieldKind, from node: AttributeSyntax, in context: some MacroExpansionContext) {
    let arguments: BitFieldMacroArguments?
    switch kind {
    case .reserved:
      arguments = ReservedMacro.parse(from: node, in: context)
    case .readWrite:
      arguments = ReadWriteMacro.parse(from: node, in: context)
    case .readOnly:
      arguments = ReadOnlyMacro.parse(from: node, in: context)
    case .writeOnly:
      arguments = WriteOnlyMacro.parse(from: node, in: context)
    }
    guard let arguments = arguments else { return nil }
    self = arguments
  }
}

struct ReservedMacro: BitFieldMacroProtocol {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "Reserved"
}

struct ReadWriteMacro: BitFieldMacroProtocol {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "ReadWrite"
}

struct ReadOnlyMacro: BitFieldMacroProtocol {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "ReadOnly"
}

struct WriteOnlyMacro: BitFieldMacroProtocol {
  typealias Arguments = BitFieldMacroArguments
  static var baseName = "WriteOnly"
}
