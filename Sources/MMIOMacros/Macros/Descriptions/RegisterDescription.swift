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

struct RegisterDescription {
  var name: TokenSyntax
  var accessLevel: DeclModifierSyntax?
  var bitWidth: Int
  var bitFields: [BitFieldDescription]
  var isSymmetric: Bool
}

extension RegisterDescription {
  func validate() throws {
    // Validate bit range in each bit field.
    for bitField in self.bitFields {
      try bitField.validate()
    }

    // FIXME: Validate bit range overlap across bit fields.
  }

  func declarations() -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create a private init and a Never instance property to prevent users from
    // instancing the layout type directly.
    declarations.append("private init() { fatalError() }")
    declarations.append("private var _never: Never")

    // Create bit field types for each field contained in the layout type.
    for bitField in self.bitFields {
      declarations.append(contentsOf: bitField.declarations())
    }

    // Create a symmetric raw type ignoring read and write constraints as unsafe
    // escape hatch.
    declarations.append(contentsOf: self.rawTypeDeclarations())

    if self.isSymmetric {
      // Create a single symmetric read-write type if all bit fields provide
      // symmetric views.
      declarations.append(contentsOf: self.readWriteTypeDeclarations())
    } else {
      // Create two asymmetric read and write types if any of the bit fields
      // provide asymmetric views.
      declarations.append(contentsOf: self.readTypeDeclarations())
      declarations.append(contentsOf: self.writeTypeDeclarations())
    }

    return declarations
  }
}

extension RegisterDescription {
  func rawTypeDeclarations() -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Create variable declaration for each bitfield.
    let bitFieldDeclarations: [DeclSyntax] = self
      .bitFields
      .map { $0.rawVariableDeclaration() }

    // Create an initializer to convert from the Read/Write types to the
    // Raw code.
    let initDeclarations: [DeclSyntax] =
      if isSymmetric {
        [
          """
          \(self.accessLevel)init(_ value: Value.ReadWrite) {
            self.storage = value.storage
          }
          """
        ]
      } else {
        [
          """
          \(self.accessLevel)init(_ value: Value.Read) {
            self.storage = value.storage
          }
          """,
          """
          \(self.accessLevel)init(_ value: Value.Write) {
            self.storage = value.storage
          }
          """,
        ]
      }

    // Produce Raw type declaration.
    declarations.append(
      """
      \(self.accessLevel)struct Raw: RegisterValueRaw {
        \(self.accessLevel)typealias Value = \(self.name)
        \(self.accessLevel)typealias Storage = UInt\(raw: self.bitWidth)
        \(self.accessLevel)var storage: Storage
        \(self.accessLevel)init(_ storage: Storage) {
          self.storage = storage
        }
        \(nodes: initDeclarations)
        \(nodes: bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func readWriteTypeDeclarations() -> [DeclSyntax] {
    var declarations = [DeclSyntax]()
    // Alias Read to ReadWrite.
    declarations.append("\(self.accessLevel)typealias Read = ReadWrite")
    // Alias Write to ReadWrite.
    declarations.append("\(self.accessLevel)typealias Write = ReadWrite")

    // Create variable declaration for each readable and writable bitfield.
    let bitFieldDeclarations: [DeclSyntax] = self
      .bitFields
      .compactMap { $0.readWriteVariableDeclaration() }

    // Produce Read-Write type declaration.
    declarations.append(
      """
      \(self.accessLevel)\
      struct ReadWrite: RegisterValueRead, RegisterValueWrite {
        \(self.accessLevel)typealias Value = \(self.name)
        var storage: UInt\(raw: self.bitWidth)
        \(self.accessLevel)init(_ value: ReadWrite) {
          self.storage = value.storage
        }
        \(self.accessLevel)init(_ value: Raw) {
          self.storage = value.storage
        }
        \(nodes: bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func readTypeDeclarations() -> [DeclSyntax] {
    var declarations = [DeclSyntax]()

    // Create variable declaration for each readable bitfield.
    let bitFieldDeclarations: [DeclSyntax] = self
      .bitFields
      .compactMap { $0.readVariableDeclaration() }

    // Produce Read type declaration.
    declarations.append(
      """
      \(self.accessLevel)struct Read: RegisterValueRead {
        \(self.accessLevel)typealias Value = \(self.name)
        var storage: UInt\(raw: self.bitWidth)
        \(self.accessLevel)init(_ value: Raw) { self.storage = value.storage }
        \(nodes: bitFieldDeclarations)
      }
      """)
    return declarations
  }

  func writeTypeDeclarations() -> [DeclSyntax] {
    var declarations = [DeclSyntax]()

    // Create accessor declarations for each writable bitfield.
    let bitFieldDeclarations: [DeclSyntax] = self
      .bitFields
      .compactMap { $0.writeVariableDeclaration() }

    // Produce Write type declaration.
    declarations.append(
      """
      \(self.accessLevel)struct Write: RegisterValueWrite {
        \(self.accessLevel)typealias Value = \(self.name)
        var storage: UInt\(raw: self.bitWidth)
        \(self.accessLevel)init(_ value: Raw) {
          self.storage = value.storage
        }
        \(self.accessLevel)init(_ value: Read) {
          // FIXME: mask off bits
          self.storage = value.storage
        }
        \(nodes: bitFieldDeclarations)
      }
      """)
    return declarations
  }
}
