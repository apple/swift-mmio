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

final class MMIOFileCheckTests: XCTestCase, @unchecked Sendable {
  func test() throws {
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
    let testFileURLs = FileManager.default.files(
      inDirectory: testsDirectoryURL,
      withPathExtension: "swift")

    // Run test setup.
    let start = DispatchTime.now()
    let configuration = try self._setup(
      packageDirectoryURL: packageDirectoryURL)
    let end = DispatchTime.now()

    // `DispatchTime.distance(to:)` is unavailable on linux.
    let duration = end.uptimeNanoseconds - start.uptimeNanoseconds
    print("Setup took \(duration) nanoseconds")

    let tests = testFileURLs.map {
      MMIOFileCheckTestCase(
        configuration: configuration,
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

  struct TestConfiguration {
    var hasLLVMFileCheck: Bool
    var buildOutputsURL: URL
  }

  func _setup(packageDirectoryURL: URL) throws -> TestConfiguration {
    let hasLLVMFileCheck: Bool
    do {
      print("Locating FileCheck...")
      _ = try sh("which FileCheck")
      hasLLVMFileCheck =
        ProcessInfo().environment["SWIFT_MMIO_USE_SIMPLE_FILECHECK"] == nil
    } catch {
      print("Failed to locate FileCheck...")
      hasLLVMFileCheck = false
    }

    if hasLLVMFileCheck {
      print("Using LLVM FileCheck")
    } else {
      print("Using Simple FileCheck")
    }

    print("Determining Swift Version...")
    let versionString = try sh(
      """
      swift --version
      """)

    let regex = #/Apple Swift version (\d+)/#
    let swift6Plus =
      if let match = versionString.firstMatch(of: regex),
        let majorVersion = Int(match.output.1),
        majorVersion > 5
      {
        true
      } else {
        false
      }

    print("Determining Dependency Paths...")
    let buildOutputsURL = URL(
      fileURLWithPath: try sh(
        """
        swift build \
          \(swift6Plus ? "--ignore-lock" : "") \
          --configuration release \
          --package-path \(packageDirectoryURL.path) \
          --show-bin-path
        """))

    print("Building MMIO...")
    _ = try sh(
      """
      swift build \
        \(swift6Plus ? "--ignore-lock" : "") \
        --configuration release \
        --package-path \(packageDirectoryURL.path)
      """)

    return .init(
      hasLLVMFileCheck: hasLLVMFileCheck,
      buildOutputsURL: buildOutputsURL)
  }
}

struct MMIOFileCheckTestCase: Sendable {
  var configuration: MMIOFileCheckTests.TestConfiguration
  var packageDirectoryURL: URL
  var testFileURL: URL

  func run() -> [LLVMDiagnostic] {
    do {
      print("Running: \(self.testFileURL.lastPathComponent)")

      let testOutputFileURL = self.configuration.buildOutputsURL
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
          -O -wmo \
          -I \(self.configuration.buildOutputsURL.path) \
          -I \(self.configuration.buildOutputsURL.path)/Modules \
          -I \(mmioVolatileDirectoryURL.path) \
          -load-plugin-executable \
            \(self.configuration.buildOutputsURL.path)/MMIOMacros#MMIOMacros \
          -parse-as-library \
          -diagnostic-style llvm
        """)

      if self.configuration.hasLLVMFileCheck {
        _ = try sh(
          """
          FileCheck \
            \(self.testFileURL.path) \
            --input-file \(testOutputFileURL.path) \
            --dump-input never
          """)
      } else {
        let fileCheck = SimpleFileCheck(
          inputFileURL: self.testFileURL,
          outputFileURL: testOutputFileURL)
        let diagnostics = fileCheck.run()
        guard diagnostics.isEmpty else {
          return diagnostics
        }
      }

    } catch let error as ShellCommandError {
      // Parse the errors.
      var message = error.error[...]
      let diagnostics = Parser.llvmDiagnostics.run(&message)
      guard let diagnostics = diagnostics else {
        XCTFail("Test failed: \(error)")
        return []
      }
      if !message.isEmpty {
        XCTFail("Failed to parse all error diagnostics, remaining: \(message)")
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
          lineNumber: diagnostic.line)))
    self.record(issue)
    #endif
  }
}

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

#endif
