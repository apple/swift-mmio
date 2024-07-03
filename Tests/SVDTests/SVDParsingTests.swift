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

#if canImport(System) && canImport(CryptoKit)
import Foundation
import SVD
import Testing

struct SVDTests {
  static let testData = Task {
    try await SVDTestData.prepare(downloadingIfNeeded: true)
  }

  @Test(
    .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil),
    arguments: try await Self.testData.value.testSVDs)
  func decode(url: URL) throws {
    let group = url.deletingLastPathComponent().lastPathComponent
    let chip = url.lastPathComponent
    let svd = "\(group)/\(chip)"

    let data = try Data(contentsOf: url)
    var device = try SVDDevice(data: data)

    if SVDTestData.knownInvalidSVDs.contains(svd) {
      withKnownIssue("Known invalid svd '\(svd)'") {
        try device.inflate()
      }
    } else {
      try device.inflate()
    }
  }
}
#endif
