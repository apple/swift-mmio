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

// FIXME: rdar://113256834,swiftlang/swift-package-manager#6935
// Remove import
import Foundation
import PackagePlugin

extension SourceModuleTarget {
  // FIXME: rdar://113256834,swiftlang/swift-package-manager#6935
  // Return `File` and not `Path`
  func sourceFile(kind: FileKind) throws -> Path {
    let files = self
      .sourceFiles
      .filter {
        switch kind.match {
        case .fileExtension(let fileExtension):
          return $0.path.extension == fileExtension
        case .fileName(let fileName):
          return $0.path.lastComponent == fileName
        }
      }

    switch files.count {
    case 0:
      // FIXME: rdar://113256834,swiftlang/swift-package-manager#6935
      // throw SVD2SwiftPluginError.missingFile(self, kind)
      return try _sourceFile(kind: kind)
    case 1:
      // FIXME: rdar://113256834,swiftlang/swift-package-manager#6935
      // return files[0]
      return files[0].path
    default:
      throw SVD2SwiftPluginError.tooManyFiles(self, kind)
    }
  }

  // FIXME: rdar://113256834,swiftlang/swift-package-manager#6935
  // Remove this function
  private func _sourceFile(kind: FileKind) throws -> Path {
    let targetDirectoryURL = URL(fileURLWithPath: self.directory.string)
    let enumerator = FileManager.default.enumerator(
      at: targetDirectoryURL,
      includingPropertiesForKeys: [])
    guard let enumerator = enumerator else {
      throw SVD2SwiftPluginError.missingFile(self, kind)
    }

    let files = enumerator
      .lazy
      .compactMap { $0 as? URL }
      .map { Path($0.path) }
      .filter {
        switch kind.match {
        case .fileExtension(let fileExtension):
          return $0.extension == fileExtension
        case .fileName(let fileName):
          return $0.lastComponent == fileName
        }
      }
      .reduce(into: [Path]()) { $0.append($1) }

    switch files.count {
    case 0:
      throw SVD2SwiftPluginError.missingFile(self, kind)
    case 1:
      return files[0]
    default:
      throw SVD2SwiftPluginError.tooManyFiles(self, kind)
    }
  }
}
