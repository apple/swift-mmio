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

extension FileManager {
  func files(
    inDirectory directoryURL: URL,
    withPathExtension pathExtension: String
  ) -> [URL] {
    let enumerator = self.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [])
    guard let enumerator = enumerator else { return [] }

    return enumerator
      .lazy
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == pathExtension }
      .sorted { $0.path < $1.path }
  }
}
