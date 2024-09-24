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

// Silence warnings about `Target` not being Sendable.
@preconcurrency import PackagePlugin

enum SVD2SwiftPluginError: Error {
  case missingFile(Target, FileKind)
  case tooManyFiles(Target, FileKind)
  case missingPeripherals(Target, String)
}

extension SVD2SwiftPluginError: CustomStringConvertible {
  var description: String {
    switch self {
    case .missingFile(let target, let fileKind):
      """
      Error: Missing \(fileKind) file in target '\(target.name)', \
      expected exactly one.
      """
    case .tooManyFiles(let target, let fileKind):
      """
      Error: Too many \(fileKind) files in target '\(target.name)', \
      expected exactly one.
      """
    case .missingPeripherals(let target, let path):
      """
      Error: Missing peripherals in \(FileKind.svd2swift) file '\(path)' \
      in target '\(target.name)', expected at least one.
      """
    }
  }
}
