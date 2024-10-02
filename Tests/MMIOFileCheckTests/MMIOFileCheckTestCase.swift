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

// FIXME: switch over to swift-testing
// XCTest is really painful for dynamic test lists

import Dispatch
import Foundation
import MMIOUtilities
import XCTest

final class MMIOFileCheckTests: XCTestCase, @unchecked Sendable {
  func test() throws {
    let selfFileURL = URL(fileURLWithPath: #filePath)
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
    print("Finding Tests...")
    let testFileURLs = FileManager.default.files(
      inDirectory: testsDirectoryURL,
      withPathExtension: "swift")

    // Run test setup step.
    print("Running Test Setup...")
    let start = DispatchTime.now()
    let (hasLLVMFileCheck, toolchainID, buildOutputsURL) = try Self.prerun(
      packageDirectoryURL: packageDirectoryURL)
    let end = DispatchTime.now()

    // `DispatchTime.distance(to:)` is unavailable on linux.
    let duration = end.uptimeNanoseconds - start.uptimeNanoseconds
    print("Setup took \(duration) nanoseconds")

    print("Running Tests...")
    DispatchQueue.concurrentPerform(iterations: testFileURLs.count) { index in
      let testFileURL = testFileURLs[index]
      let diagnostics = Self.run(
        testFileURL: testFileURL,
        hasLLVMFileCheck: hasLLVMFileCheck,
        toolchainID: toolchainID,
        packageDirectoryURL: packageDirectoryURL,
        buildOutputsURL: buildOutputsURL)
      for diagnostic in diagnostics {
        self.record(diagnostic: diagnostic)
      }
    }

    print("Finished running \(testFileURLs.count) tests")
  }

  static func prerun(
    packageDirectoryURL: URL
  ) throws -> (Bool, String, URL) {
    let environment = ProcessInfo.processInfo.environment

    let ci: Bool
    if environment["CI"] != nil {
      print("Running in CI...")
      ci = true
    } else {
      ci = false
    }

    print("Determining Swift Toolchain...")
    let toolchainID: String

    if let toolchain = environment["TOOLCHAINS"] {
      print("TOOLCHAINS set.")
      toolchainID = toolchain
    } else if ci {
      print("Running in CI. Leaving TOOLCHAINS empty.")
      toolchainID = ""
    } else {
      print("TOOLCHAINS not set.")
      #if os(macOS)
      print("Searching for swift-latest toolchain")
      toolchainID = try sh(
        """
        plutil \
          -extract CFBundleIdentifier raw \
          -o - \
          /Library/Developer/Toolchains/swift-latest.xctoolchain/Info.plist
        """)
      #else
      toolchainID = ""
      #endif
    }
    print("Using TOOLCHAINS=\(toolchainID)")

    print("Determining Swift Compiler Version...")
    let versionString = try sh("TOOLCHAINS=\(toolchainID) swift --version")
    let regex = #/Swift version (\d+)/#
    let swift6Plus =
      if let match = versionString.firstMatch(of: regex),
        let majorVersion = Int(match.output.1),
        majorVersion > 5
      {
        true
      } else {
        false
      }
    print("Using Swift Compiler Version \(swift6Plus ? 6 : 5)")

    if !swift6Plus {
      throw XCTSkip("Unsupported on Swift < 6")
    }

    let hasLLVMFileCheck: Bool
    do {
      print("Locating FileCheck...")
      _ = try sh("which FileCheck")
      hasLLVMFileCheck = environment["SWIFT_MMIO_USE_SIMPLE_FILECHECK"] == nil
    } catch {
      print("Failed to locate FileCheck...")
      hasLLVMFileCheck = false
    }

    if hasLLVMFileCheck {
      print("Using LLVM FileCheck")
    } else {
      print("Using Simple FileCheck")
    }

    print("Determining Dependency Paths...")
    let buildOutputsURL = URL(
      fileURLWithPath: try sh(
        """
        TOOLCHAINS=\(toolchainID) swift build \
          --ignore-lock \
          --configuration release \
          --package-path \(packageDirectoryURL.path) \
          --show-bin-path
        """))

    if ci {
      print("Skipping building MMIO...")
    } else {
      print("Building MMIO...")
      _ = try sh(
        """
        TOOLCHAINS=\(toolchainID) swift build \
          --ignore-lock \
          --configuration release \
          --package-path \(packageDirectoryURL.path) \
          --verbose
        """, collectStandardOutput: false)
    }

    return (hasLLVMFileCheck, toolchainID, buildOutputsURL)
  }

  static func run(
    testFileURL: URL,
    hasLLVMFileCheck: Bool,
    toolchainID: String,
    packageDirectoryURL: URL,
    buildOutputsURL: URL
  ) -> [LLVMDiagnostic] {
    do {
      print("Running: \(testFileURL.lastPathComponent)")

      let testOutputFileURL =
        buildOutputsURL
        .appendingPathComponent(testFileURL.lastPathComponent)
        .appendingPathExtension("ll")
      let mmioVolatileDirectoryURL =
        packageDirectoryURL
        .appendingPathComponent("Sources")
        .appendingPathComponent("MMIOVolatile")

      do {
        print("RAUHUL1:")
        try print(sh("ls -asl"))
      } catch {
        print(error)
      }
      do {
        print("RAUHUL2:")
        try print(sh("ls -asl \(buildOutputsURL.path)"))
      } catch {
        print(error)
      }
      do {
        print("RAUHUL3:")
        try print(sh("ls -asl \(buildOutputsURL.path)/Modules"))
      } catch {
        print(error)
      }


      _ = try sh(
        """
        TOOLCHAINS=\(toolchainID) swiftc \
          -emit-ir \(testFileURL.path) \
          -o \(testOutputFileURL.path) \
          -O -wmo \
          -I \(buildOutputsURL.path)/Modules \
          -I \(mmioVolatileDirectoryURL.path) \
          -load-plugin-executable \
            \(buildOutputsURL.path)/MMIOMacros-tool#MMIOMacros \
          -parse-as-library \
          -diagnostic-style llvm \
          -v \
          -Rmodule-loading
        """)

      if hasLLVMFileCheck {
        _ = try sh(
          """
          FileCheck \
            \(testFileURL.path) \
            --input-file \(testOutputFileURL.path) \
            --dump-input never
          """)
      } else {
        let fileCheck = SimpleFileCheck(
          inputFileURL: testFileURL,
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
