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

import MMIOUtilities
import XCTest

@testable import SVD
@testable import SVD2Swift

// swift-format-ignore: AlwaysUseLowerCamelCase
func XCTAssertSVD2SwiftOutput(
  svdDevice: SVDDevice,
  options: ExportOptions,
  expected: [String: String],
  file: StaticString = #file,
  line: UInt = #line
) {
  var output = Output.inMemory([:])
  do {
    var device = svdDevice
    try device.inflate()
    try device.export(with: options, to: &output)
  } catch {
    XCTFail(
      "export operation failed: \(error)",
      file: file,
      line: line)
    return
  }

  guard case .inMemory(let actual) = output else {
    XCTFail(
      "\(#function) can only be used with an in memory output writer",
      file: file,
      line: line)
    return
  }

  let expectedFiles = expected.keys.sorted()
  let actualFiles = actual.keys.sorted()

  guard expectedFiles == actualFiles else {
    XCTFail(
      diff(expected: expectedFiles, actual: actualFiles, noun: "files"),
      file: file,
      line: line)
    return
  }

  for virtualFile in expectedFiles {
    guard
      let expectedContent = expected[virtualFile],
      let actualContent = actual[virtualFile]
    else { fatalError() }

    guard expectedContent != actualContent else { continue }

    XCTFail(
      """
      \(virtualFile): \
      \(diff(expected: expectedContent, actual: actualContent, noun: "content"))
      """,
      file: file,
      line: line)
  }
}

final class SVD2SwiftTests: XCTestCase {}
