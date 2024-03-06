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

struct FileKind {
  enum Match: CustomStringConvertible {
    case fileExtension(String)
    case fileName(String)

    var description: String {
      switch self {
      case .fileExtension(let fileExtension):
        fileExtension
      case .fileName(let fileName):
        fileName
      }
    }
  }

  var match: Match
  var humanDescription: String
}

extension FileKind: CustomStringConvertible {
  var description: String { "\(self.humanDescription) ('\(self.match)')" }
}

extension FileKind {
  static let svd = Self(
    match: .fileExtension("svd"),
    humanDescription: "System View Description")

  static let svd2swift = Self(
    match: .fileName("svd2swift.json"),
    humanDescription: "SVD to Swift Plugin Configuration")
}
