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

import PackagePlugin

extension SourceModuleTarget {
  func sourceFile(kind: FileKind) throws -> File {
    let files = self
      .sourceFiles
      .filter {
        switch kind.match {
        case .fileExtension(let fileExtension):
          return $0.url.pathExtension == fileExtension
        case .fileName(let fileName):
          return $0.url.lastPathComponent == fileName
        }
      }

    switch files.count {
    case 0: throw SVD2SwiftPluginError.missingFile(self, kind)
    case 1: return files[0]
    default: throw SVD2SwiftPluginError.tooManyFiles(self, kind)
    }
  }
}
