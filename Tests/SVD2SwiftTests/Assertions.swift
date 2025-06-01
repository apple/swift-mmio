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

import MMIOUtilities
import Testing

@testable import SVD
@testable import SVD2Swift

extension ExportOptions {
  static let testDefault = Self(
    indentation: .space(2),
    accessLevel: nil,
    selectedPeripherals: [],
    namespaceUnderDevice: false,
    instanceMemberPeripherals: false,
    overrideDeviceName: nil)
}

func assertSVD2SwiftOutput(
  svdDevice: SVDDevice,
  options: ExportOptions = .testDefault,
  expected: [String: String],
  sourceLocation: SourceLocation = #_sourceLocation
) {
  var output = Output.inMemory([:])
  do {
    var device = svdDevice
    try device.inflate()
    try device.export(with: options, to: &output)
  } catch {
    Issue.record(
      "export operation failed: \(error)",
      sourceLocation: sourceLocation)
    return
  }

  guard case .inMemory(let actual) = output else {
    Issue.record(
      "\(#function) can only be used with an in memory output writer",
      sourceLocation: sourceLocation)
    return
  }

  let expectedFiles = expected.keys.sorted()
  let actualFiles = actual.keys.sorted()

  guard expectedFiles == actualFiles else {
    Issue.record(
      Comment(
        rawValue: diff(
          expected: expectedFiles,
          actual: actualFiles,
          noun: "files")),
      sourceLocation: sourceLocation)
    return
  }

  for virtualFile in expectedFiles {
    guard
      let expectedContent = expected[virtualFile],
      let actualContent = actual[virtualFile]
    else { fatalError() }

    guard expectedContent != actualContent else { continue }

    Issue.record(
      """
      \(virtualFile): \
      \(diff(expected: expectedContent, actual: actualContent, noun: "content"))
      """,
      sourceLocation: sourceLocation)
  }
}

struct SVD2SwiftTests {}
