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

extension PatternBindingSyntax {
  func requireType(
    _ context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) throws -> TypeSyntax {
    guard let type = self.typeAnnotation?.type else {
      throw context.error(
        at: self,
        message: .expectedTypeAnnotation(),
        fixIts: .insertBindingType(node: self))
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
