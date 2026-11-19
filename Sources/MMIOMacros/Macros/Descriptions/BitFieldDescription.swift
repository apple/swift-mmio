//===----------------------------------------------------------------------===//
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
import SwiftSyntaxBuilder

struct BitFieldDescription {
  var attribute: AttributeSyntax
  var accessLevel: DeclModifierSyntax?
  var bitWidth: Int
  var type: any BitFieldMacro.Type
  var fieldName: IdentifierPatternSyntax
  var fieldType: TypeSyntax
  var bitRanges: [BitRange]
  var bitRangeExpressions: [ExprSyntax]
  var projectedType: ExprSyntax?
}

extension BitFieldDescription {
  // FIXME: compute this once
  func storageType() -> DeclReferenceExprSyntax {
    .init(baseName: .identifier("UInt\(self.bitWidth)"))
  }
}

extension BitFieldDescription {
  func declarations() -> [DeclSyntax] {
    precondition(!self.bitRanges.isEmpty)
    let projection = self.projectedType.map { "\($0.trimmed)" } ?? "Never"
    let storageBits = 0...(self.bitWidth - 1)
    let bitRanges = self.bitRanges.reversed().reduce("_MMIOBitFieldRangeEnd") {
      // Clamp to the storage width; a partial range has an open bound.
      let range = Range($1.canonicalizedClosedRange.clamped(to: storageBits))
      let (lowerBound, upperBound) = (range.lowerBound, range.upperBound)
      return "_MMIOBitFieldRange<\(lowerBound), \(upperBound), \($0)>"
    }
    return [
      """
      \(self.accessLevel)typealias \(self.fieldType) = _MMIOBitField<Self, \
      \(self.storageType()), \(raw: projection), \(raw: bitRanges)>
      """
    ]
  }
}

extension BitFieldDescription {
  func rawVariableDeclaration() -> DeclSyntax {
    """
    @export(implementation) @inline(always)
    \(self.accessLevel)var \(self.fieldName): \(self.storageType()) {
      @export(implementation) @inline(always) get {
        \(self.fieldType).extractBits(from: self.storage)
      }
      @export(implementation) @inline(always) set {
        \(self.fieldType).insertBits(newValue, into: &self.storage)
      }
    }
    """
  }

  func readWriteVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isReadable,
      self.type.isWriteable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    return """
      @export(implementation) @inline(always)
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @export(implementation) @inline(always) get {
          \(self.fieldType).extract(from: self.storage)
        }
        @export(implementation) @inline(always) set {
          \(self.fieldType).insert(newValue, into: &self.storage)
        }
      }
      """
  }

  func readVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isReadable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    return """
      @export(implementation) @inline(always)
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @export(implementation) @inline(always) get {
          \(self.fieldType).extract(from: self.storage)
        }
      }
      """
  }

  func writeVariableDeclaration() -> DeclSyntax? {
    guard
      self.type.isWriteable,
      let projectedType = self.projectedType
    else {
      return nil
    }

    // FIXME: improve warning message
    // blocked-by: rdar://116130327 (Customizable deprecation messages)

    return """
      @export(implementation) @inline(always)
      \(self.accessLevel)var \(self.fieldName): \(projectedType) {
        @available(*, deprecated, message: "API misuse; read from write view returns the value to be written, not the value initially read.")
        @export(implementation) @inline(always) get {
          \(self.fieldType).extract(from: self.storage)
        }
        @export(implementation) @inline(always) set {
          \(self.fieldType).insert(newValue, into: &self.storage)
        }
      }
      """
  }
}
