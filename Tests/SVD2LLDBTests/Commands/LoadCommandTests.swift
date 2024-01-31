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

@testable import SVD2LLDB

final class LoadCommandTests: XCTestCase {
  func test_argumentParsing() {
    XCTAssertCommand(
      command: LoadCommand.self,
      arguments: ["--help"],
      success: true,
      debugger: "",
      result: """
        OVERVIEW: Load an SVD file from disk.

        USAGE: svd load <path>

        ARGUMENTS:
          <path>                  Path to SVD file.

        OPTIONS:
          -h, --help              Show help information.

        """)
  }
}
