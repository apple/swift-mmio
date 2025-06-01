//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation

struct SVD2SwiftPluginConfigurationDecodingError {
  var description: String
}

extension SVD2SwiftPluginConfigurationDecodingError: CustomStringConvertible {
  init(url: URL, error: DecodingError) {
    func format(_ codingPath: [any CodingKey]) -> String {
      guard codingPath.isEmpty else {
        var path = ""
        for key in codingPath {
          if !path.isEmpty {
            path.append(".")
          }
          if let index = key.intValue {
            path.append("[")
            path.append("\(index)")
            path.append("]")
          } else {
            path.append(key.stringValue)
          }
        }
        return path
      }
      return "<root>"
    }

    let errorFragment =
      switch error {
      case .typeMismatch(let type, let context):
        "Expected type \"\(type)\" at path \"\(format(context.codingPath))\"."
      case .valueNotFound(_, let context):
        "Expected value at path \"\(format(context.codingPath))\"."
      case .keyNotFound(let key, let context):
        "Expected key at path \"\(format(context.codingPath + [key]))\"."
      case .dataCorrupted(let context):
        "Data corrupted at path \"\(format(context.codingPath))\"."
      default:
        "Unknown decoding error: \(error)"
      }
    self.description = """
      \(url.path):1:1: \
      Failed to read \(FileKind.svd2swift): \
      \(errorFragment)
      """
  }
}

extension SVD2SwiftPluginConfigurationDecodingError: Error {}
