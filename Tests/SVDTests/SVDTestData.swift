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
import CryptoKit
import Foundation
import MMIOUtilities
import System
import Testing

struct SVDTestData {
  let testSVDs: [URL]
}

// These constants will need to be updated if the external resources change.
extension SVDTestData {
  // swift-format-ignore: NeverForceUnwrap
  /// The URL of the remote test data.
  static let testDataRemoteURL = URL(
    string: """
      https://github.com/cmsis-svd/cmsis-svd-data/archive/\
      853bb02dc1ac496576fd9de49483a35fa43ca90e.zip
      """)!

  /// The SHA 256 of the zip file containing the SVD files.
  static let testDataZipFileSHA256 =
    "e0e3c2e897c130b99cf0979d3d92bd7796003a63ea65dc12fdac42aed0ad7a57"

  /// The SHA 256 of all SVD files contained in the zip.
  ///
  /// Validated manually by via:
  /// ```bash
  /// fd '\.svd$' -IH .build/cmsis-svd-data \
  ///   | sort \
  ///   | xargs cat \
  ///   | shasum -a 256 -
  /// ```
  static let testDataSVDFilesSHA256 =
    "1e937f6cfcd2d78861ed9870a37bf2bdda9c630fcb6206b2fd146892eb4f05ca"

  /// The expected number of files in the zip.
  static let testDataSVDFilesCount = 1880

  /// The set of known invalid SVDs which fail inflate.
  static let knownInvalidSVDs: Set<String> = [
    // Invalid derived-from relationships
    "Renesas/R7FA4M1AB.svd",
    "Renesas/R7FA4W1AD.svd",
  ]

  static let buildDirectory = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent(".build")

  static let testDataZipFile = Self.buildDirectory
    .appendingPathComponent("cmsis-svd-data.zip")

  static let testDataDirectory = Self.buildDirectory
    .appendingPathComponent("cmsis-svd-data")
}

extension SVDTestData {
  static func prepare(downloadingIfNeeded: Bool) async throws -> Self {
    let fm = FileManager.default
    let us = URLSession.shared

    do {
      print("Attempting to hash file at '\(Self.testDataZipFile.path)")
      let sha256 = try fm.hashOfFile(
        at: Self.testDataZipFile,
        using: CryptoKit.SHA256.self)
      print("Validating hash of file at '\(Self.testDataZipFile.path)")
      try #require(
        String(sha256) == self.testDataZipFileSHA256,
        """
        Test data at '\(Self.testDataZipFile.path)' does not match \
        expected checksum, please remove file and re-run: expected 'SHA256 \
        digest: \(Self.testDataZipFileSHA256)' but found '\(sha256)'.
        """)
    } catch Errno.noSuchFileOrDirectory where downloadingIfNeeded {
      print("Downloading test data from '\(Self.testDataRemoteURL)'")
      let downloadURL = try await us.download(from: Self.testDataRemoteURL).0
      print("Hashing downloaded file at '\(downloadURL.path)'")
      let sha256 = try fm.hashOfFile(at: downloadURL, using: CryptoKit.SHA256.self)
      print("Validating hash of file at '\(Self.testDataDirectory.path)")
      try #require(
        String(sha256) == self.testDataZipFileSHA256,
        """
        Downloaded test data at '\(downloadURL.path)' does not match \
        expected checksum, please validate data: expected 'SHA256 digest: \
        \(self.testDataZipFileSHA256)' but found '\(sha256)'.
        """)
      print(
        """
        Moving file from '\(downloadURL.path)' to '\(self.testDataZipFile.path)'
        """)
      try fm.moveItem(at: downloadURL, to: self.testDataZipFile)
    }

    do {
      print("Attempting to hash files at '\(Self.testDataDirectory.path)")
      let sha256 = try fm.hashOfFiles(
        inDirectory: Self.testDataDirectory,
        withPathExtension: "svd",
        using: CryptoKit.SHA256.self)
      print("Validating hash of files at '\(Self.testDataDirectory.path)")
      try #require(
        String(sha256) == self.testDataSVDFilesSHA256,
        """
        Test data at '\(Self.testDataDirectory.path)' does not match \
        the expected checksum, please remove directory and re-run: \
        Expected 'SHA256 digest: \(Self.testDataZipFileSHA256)' but found \
        '\(sha256)'.
        """)
    } catch Errno.noSuchFileOrDirectory where downloadingIfNeeded {
      print("Extracting download at '\(Self.testDataZipFile.path)'")
      _ = try sh(
        """
        unzip -o \
          -d \(Self.testDataDirectory.path) \
          \(Self.testDataZipFile.path)
        """)
      print("Hashing extracted files at '\(Self.testDataDirectory.path)'")
      let sha256 = try fm.hashOfFiles(
        inDirectory: Self.testDataDirectory,
        withPathExtension: "svd",
        using: CryptoKit.SHA256.self)
      print("Validating hash of files at '\(Self.testDataDirectory.path)")
      try #require(
        String(sha256) == self.testDataSVDFilesSHA256,
        """
        Extracted test data at '\(Self.testDataDirectory.path)' does \
        not match the expected checksum, please validate data: Expected \
        'SHA256 digest: \(self.testDataSVDFilesSHA256)' but found \
        '\(sha256)'.
        """)
    }

    print("Locating all SVD files in '\(Self.testDataDirectory.path)'")
    let testSVDs = FileManager.default.files(
      inDirectory: Self.testDataDirectory,
      withPathExtension: "svd")

    print("Validating all SVD files found")
    try #require(
      testSVDs.count == Self.testDataSVDFilesCount,
      "Failed to locate all expected SVD files")

    return Self(testSVDs: testSVDs)
  }
}
#endif
