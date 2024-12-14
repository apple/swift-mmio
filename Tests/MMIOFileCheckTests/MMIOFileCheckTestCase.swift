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

import Dispatch
import Foundation
import MMIOUtilities
import Testing

struct MMIOFileCheckTests: @unchecked Sendable {
  struct Configuration {
    var hasLLVMFileCheck: Bool
    var toolchainID: String
    var packageDirectory: URL
    var buildOutputs: URL

    var buildModulesDirectory: URL {
      self.buildOutputs
        .appendingPathComponent("Modules")
    }

    var buildMMIOMacrosFile: URL {
      self.buildOutputs
        .appendingPathComponent("MMIOMacros-tool")
    }

    var mmioVolatileDirectory: URL {
      self.packageDirectory
        .appendingPathComponent("Sources")
        .appendingPathComponent("MMIOVolatile")
    }
  }

  static let _configuration = Result { try Self.configure() }
  static var configuration: Configuration {
    get throws { try self._configuration.get() }
  }

  /// The test files in this target's "Tests" subdirectory.
  static let testFiles: [URL] = {
    let testsDirectory = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .appendingPathComponent("Tests")
    return FileManager.default.files(
      inDirectory: testsDirectory,
      withPathExtension: "swift")
  }()

  static func configure() throws -> Configuration {
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
    if true {
      toolchainID = "org.swift.62202412101a"
    } else if let toolchain = environment["TOOLCHAINS"] {
      print("TOOLCHAINS set.")
      toolchainID = toolchain
    } else if ci {
      print("Running in CI. Leaving TOOLCHAINS empty.")
      toolchainID = ""
    } else {
      print("TOOLCHAINS not set.")
      #if os(macOS)
      print("Searching for swift-latest toolchain")
      do {
        toolchainID = try sh(
          """
          plutil \
            -extract CFBundleIdentifier raw \
            -o - \
            /Library/Developer/Toolchains/swift-latest.xctoolchain/Info.plist
          """)
      } catch {
        print("Failed to locate toolchain by plist: \(error)")
        toolchainID = ""
      }
      #endif
    }
    print("Using TOOLCHAINS=\(toolchainID)")

    let hasLLVMFileCheck: Bool
    if environment["SWIFT_MMIO_USE_SIMPLE_FILECHECK"] != nil {
      print("Using Simple FileCheck (forced)")
      hasLLVMFileCheck = false
    } else if case .success = Result(catching: { try sh("which FileCheck") }) {
      print("Using LLVM FileCheck")
      hasLLVMFileCheck = true
    } else {
      print("Using Simple FileCheck (no llvm)")
      hasLLVMFileCheck = false
    }

    let packageDirectory = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    print("Determining Dependency Paths...")
    let buildOutputs = URL(
      fileURLWithPath: try sh(
        """
        TOOLCHAINS=\(toolchainID) swift build \
          --ignore-lock \
          --configuration release \
          --package-path \(packageDirectory.path) \
          --show-bin-path
        """))

    #if DEBUG
    print("Building MMIO...")
    _ = try sh(
      """
      TOOLCHAINS=\(toolchainID) swift build \
        --ignore-lock \
        --configuration release \
        --package-path \(packageDirectory.path)
      """, collectStandardOutput: false)
    #endif

    return Configuration(
      hasLLVMFileCheck: hasLLVMFileCheck,
      toolchainID: toolchainID,
      packageDirectory: packageDirectory,
      buildOutputs: buildOutputs)
  }

  @Test(arguments: Self.testFiles)
  func fileCheck(testFile: URL) throws {
    let configuration = try Self.configuration

    let testOutputFile = configuration.buildOutputs
      .appendingPathComponent(testFile.lastPathComponent)
      .appendingPathExtension("ll")

    let compileSuccess = LLVMDiagnostic.parsingShellOutput(
      """
      TOOLCHAINS=\(configuration.toolchainID) swiftc \
        -emit-ir \(testFile.path) \
        -o \(testOutputFile.path) \
        -O -wmo \
        -I \(configuration.buildModulesDirectory.path) \
        -I \(configuration.mmioVolatileDirectory.path) \
        -load-plugin-executable \(configuration.buildMMIOMacrosFile.path)#MMIOMacros \
        -parse-as-library \
        -diagnostic-style llvm
      """)
    guard compileSuccess else { return }

    let fileCheckSuccess: Bool
    if configuration.hasLLVMFileCheck {
      fileCheckSuccess = LLVMDiagnostic.parsingShellOutput(
        """
        FileCheck \
          \(testFile.path) \
          --input-file \(testOutputFile.path) \
          --dump-input never
        """)
    } else {
      let fileCheck = SimpleFileCheck(
        inputFile: testFile,
        outputFile: testOutputFile)
      let diagnostics = fileCheck.run()
      for diagnostic in diagnostics {
        diagnostic.recordAsIssue()
      }
      fileCheckSuccess = diagnostics.isEmpty
    }

    guard fileCheckSuccess else { return }
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

extension LLVMDiagnostic {
  static func parsingShellOutput(_ command: String) -> Bool {
    do throws(ShellCommandError) {
      _ = try sh(command)
    } catch let shellCommandError {
      // Parse the errors.
      var message = shellCommandError.error[...]
      let diagnostics = Parser.llvmDiagnostics.run(&message)
      guard let diagnostics = diagnostics else {
        Issue.record(shellCommandError)
        return false
      }
      if !message.isEmpty {
        Issue.record(
          "Failed to parse all error diagnostics, remaining: \(message)")
      }
      for diagnostic in diagnostics {
        diagnostic.recordAsIssue()
      }
      return false
    }
    return true
  }

  func recordAsIssue() {
    // FIXME: this emits notes as errors
    Issue.record(
      Comment(rawValue: self.message),
      sourceLocation: .init(
        fileID: self.file,
        filePath: self.file,
        line: self.line,
        column: self.column))
  }
}
