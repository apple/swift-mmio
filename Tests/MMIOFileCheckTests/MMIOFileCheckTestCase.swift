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

#if !os(Linux)
// FIXME: switch over to swift-testing
// XCTest is really painful for dynamic test lists

import Dispatch
import Foundation
import XCTest

final class MMIOFileCheckTests: XCTestCase {
  func test() {
    let selfFileURL = URL(filePath: #file)
    let selfDirectoryURL =
      selfFileURL
      .deletingLastPathComponent()
    let packageDirectoryURL =
      selfDirectoryURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let buildDirectoryURL =
      packageDirectoryURL
      .appending(path: ".build")
      .appending(path: "FileCheck")
    let includeDirectoryURL =
      buildDirectoryURL
      .appending(path: "release")
    let testsDirectoryURL =
      selfDirectoryURL
      .appending(path: "Tests")

    // Get a list of the test files from disk.
    let testFileURLs =
      try! FileManager
      .default
      .contentsOfDirectory(
        at: testsDirectoryURL,
        includingPropertiesForKeys: []
      )
      .filter { $0.pathExtension == "swift" }

    let commonSetup = MMIOFileCheckTestCaseCommonSetup(
      buildDirectoryURL: buildDirectoryURL,
      packageDirectoryURL: packageDirectoryURL)
    var tests = [MMIOFileCheckTestCase]()
    for testFileURL in testFileURLs {
      tests.append(
        MMIOFileCheckTestCase(
          commonSetup: commonSetup,
          testFileURL: testFileURL,
          buildDirectoryURL: buildDirectoryURL,
          includeDirectoryURL: includeDirectoryURL))
    }

    DispatchQueue.concurrentPerform(iterations: tests.count) { index in
      let test = tests[index]
      for issue in test.run() {
        self.record(issue)
      }
    }

    print("Finished running \(tests.count) tests")
  }
}

class MMIOFileCheckTestCaseCommonSetup {
  var buildDirectoryURL: URL
  var packageDirectoryURL: URL
  var lock: NSLock
  var buildResult: Result<Void, Error>?

  init(buildDirectoryURL: URL, packageDirectoryURL: URL) {
    self.buildDirectoryURL = buildDirectoryURL
    self.packageDirectoryURL = packageDirectoryURL
    self.lock = .init()
    self.buildResult = nil
  }

  func setup() throws {
    try self.lock.withLock {
      if let buildResult = buildResult { return try buildResult.get() }
      let start = DispatchTime.now()
      let buildResult = Result { try self._setup() }
      let end = DispatchTime.now()
      print("Setup took \(start.distance(to: end))")
      self.buildResult = buildResult
      return try buildResult.get()
    }
  }

  private func _setup() throws {
    print("Locating FileCheck...")
    _ = try sh("which FileCheck")

    print("Building MMIO...")
    _ = try sh(
      """
      swift build \
        --configuration release \
        --triple arm64-apple-macosx14.0 \
        --scratch-path \(self.buildDirectoryURL.path) \
        --package-path \(self.packageDirectoryURL.path)
      """)
  }
}

struct MMIOFileCheckTestCase {
  var commonSetup: MMIOFileCheckTestCaseCommonSetup
  var testFileURL: URL
  var buildDirectoryURL: URL
  var includeDirectoryURL: URL

  func run() -> [XCTIssue] {
    do {
      try self.commonSetup.setup()
    } catch {
      XCTFail("Setup failed: \(error)")
      return []
    }

    print("Running: \(self.testFileURL.lastPathComponent)")

    let outputFileURL = self.buildDirectoryURL
      .appending(path: self.testFileURL.lastPathComponent)
      .appendingPathExtension("ll")

    do {
      _ = try sh(
        """
        swiftc \
          -emit-ir \(self.testFileURL.path) \
          -o \(outputFileURL.path) \
          -target arm64-apple-macosx14.0 \
          -O \
          -I \(self.includeDirectoryURL.path) \
          -load-plugin-executable \
            \(self.includeDirectoryURL.path)/MMIOMacros#MMIOMacros \
          -parse-as-library
        """)
    } catch {
      return [
        XCTIssue(
          type: .assertionFailure,
          compactDescription: "\(error)",
          detailedDescription: nil,
          sourceCodeContext: .init(
            callStack: [],
            location: .init(filePath: self.testFileURL.path, lineNumber: 1)),
          associatedError: error,
          attachments: [])
      ]
    }

    do {
      _ = try sh(
        """
        FileCheck \
          \(self.testFileURL.path) \
          --input-file \(outputFileURL.path) \
          --dump-input never
        """)
      _ = try sh(
        """
        rm \(outputFileURL.path)
        """)

    } catch let shellCommandError as ShellCommandError {
      // Parse the error, emit diagnostic if parsing failed.
      var message = shellCommandError.error[...]
      let (diagnostics, rest) = Parser.fileCheckDiagnostics.parse(&message)

      guard let diagnostics = diagnostics, rest.isEmpty else {
        XCTFail("Failed to parse FileCheck error output")
        return [
          XCTIssue(
            type: .assertionFailure,
            compactDescription: "\(shellCommandError)",
            detailedDescription: nil,
            sourceCodeContext: .init(
              callStack: [],
              location: .init(filePath: testFileURL.path, lineNumber: 1)),
            associatedError: shellCommandError,
            attachments: [])
        ]
      }

      return diagnostics.map { diagnostic in
        XCTIssue(
          type: .assertionFailure,  // FIXME: this emits notes as errors
          compactDescription: diagnostic.message,
          detailedDescription: nil,
          sourceCodeContext: .init(
            callStack: [],
            location: .init(
              filePath: diagnostic.file,
              lineNumber: diagnostic.line)),
          associatedError: shellCommandError,
          attachments: [])
      }
    } catch {
      fatalError("Unexpected error: \(error)")
    }

    return []
  }
}

#endif
