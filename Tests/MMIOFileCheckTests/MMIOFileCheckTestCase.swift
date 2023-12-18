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

#if os(macOS)
// FIXME: switch over to swift-testing
// XCTest is really painful for dynamic test lists

import Dispatch
import Foundation
import XCTest
import MMIOUtilities

final class MMIOFileCheckTests: XCTestCase {
  func test() {
    let selfFileURL = URL(fileURLWithPath: #file)
    let selfDirectoryURL =
      selfFileURL
      .deletingLastPathComponent()
    let packageDirectoryURL =
      selfDirectoryURL
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let testsDirectoryURL =
      selfDirectoryURL
      .appendingPathComponent("Tests")

    // Get a list of the test files from disk.
    let testFileURLs =
      try! FileManager
      .default
      .contentsOfDirectory(
        at: testsDirectoryURL,
        includingPropertiesForKeys: []
      )
      .filter { $0.pathExtension == "swift" }

    let setup = MMIOFileCheckTestCaseSetup(
      packageDirectoryURL: packageDirectoryURL)
    let tests = testFileURLs.map {
      MMIOFileCheckTestCase(
        setup: setup,
        packageDirectoryURL: packageDirectoryURL,
        testFileURL: $0)
    }

    DispatchQueue.concurrentPerform(iterations: tests.count) { index in
      let test = tests[index]
      let diagnostics = test.run()
      for diagnostic in diagnostics {
        self.record(diagnostic: diagnostic)
      }
    }

    print("Finished running \(tests.count) tests")
  }
}

class MMIOFileCheckTestCaseSetup {
  struct Result {
    var buildOutputsURL: URL
  }

  var packageDirectoryURL: URL
  var lock: NSLock
  var result: Swift.Result<Result, Error>?

  init(packageDirectoryURL: URL) {
    self.packageDirectoryURL = packageDirectoryURL
    self.lock = .init()
    self.result = nil
  }

  func run() throws -> Result {
    // `NSLock.withLock(_:)` is unavailable on linux.
    self.lock.lock()
    defer { self.lock.unlock() }
    if let result = self.result { return try result.get() }

    // Run the common setup phase and record the time it took.
    let start = DispatchTime.now()
    let result = Swift.Result { try self._run() }
    let end = DispatchTime.now()

    // `DispatchTime.distance(to:)` is unavailable on linux.
    let duration = end.uptimeNanoseconds - start.uptimeNanoseconds
    print("Setup took \(duration) nanoseconds")

    // Cache the setup result.
    self.result = result
    return try result.get()
  }

  private func _run() throws -> Result {
    print("Locating FileCheck...")
    _ = try sh("which FileCheck")

    print("Determining Dependency Paths...")
    let buildOutputsURL = URL(
      fileURLWithPath: try sh(
        """
        swift build \
          --configuration release \
          --package-path \(self.packageDirectoryURL.path) \
          --show-bin-path
        """))

    print("Building MMIO...")
    _ = try sh(
      """
      swift build \
        --configuration release \
        --package-path \(self.packageDirectoryURL.path)
      """)

    return .init(buildOutputsURL: buildOutputsURL)
  }
}

struct MMIOFileCheckTestCase {
  var setup: MMIOFileCheckTestCaseSetup
  var packageDirectoryURL: URL
  var testFileURL: URL

  func run() -> [LLVMDiagnostic] {
    do {
      let paths = try self.setup.run()

      print("Running: \(self.testFileURL.lastPathComponent)")

      let testOutputFileURL = paths.buildOutputsURL
        .appendingPathComponent(self.testFileURL.lastPathComponent)
        .appendingPathExtension("ll")
      let mmioVolatileDirectoryURL = self.packageDirectoryURL
        .appendingPathComponent("Sources")
        .appendingPathComponent("MMIOVolatile")

      _ = try sh(
        """
        swiftc \
          -emit-ir \(self.testFileURL.path) \
          -o \(testOutputFileURL.path) \
          -O \
          -I \(paths.buildOutputsURL.path) \
          -I \(mmioVolatileDirectoryURL.path) \
          -load-plugin-executable \
            \(paths.buildOutputsURL.path)/MMIOMacros#MMIOMacros \
          -parse-as-library
        """)

      _ = try sh(
        """
        FileCheck \
          \(self.testFileURL.path) \
          --input-file \(testOutputFileURL.path) \
          --dump-input never
        """)

      _ = try sh("rm \(testOutputFileURL.path)")
    } catch let error as ShellCommandError {
      // Parse the errors.
      var message = error.error[...]
      let diagnostics = Parser.llvmDiagnostics.run(&message)
      guard let diagnostics = diagnostics, message.isEmpty else {
        XCTFail("Test failed: \(error)")
        return []
      }
      return diagnostics
    } catch {
      fatalError("Unexpected error: \(error)")
    }

    return []
  }
}

extension XCTestCase {
  func record(diagnostic: LLVMDiagnostic) {
    #if os(Linux)
    XCTFail("Test failed with error: \(diagnostic)")
    #else
    let issue = XCTIssue(
      type: .assertionFailure,  // FIXME: this emits notes as errors
      compactDescription: diagnostic.message,
      sourceCodeContext: .init(
        location: .init(
          filePath: diagnostic.file,
          lineNumber: diagnostic.line))
    )
    self.record(issue)
    #endif
  }
}

#endif
