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

enum FileCheckDiagnosticKind: String {
  case error
  case note
}

extension FileCheckDiagnosticKind: Equatable {}

struct FileCheckDiagnostic {
  var file: String
  var line: Int
  var column: Int
  var kind: FileCheckDiagnosticKind
  var message: String
}

extension FileCheckDiagnostic: CustomStringConvertible {
  var description: String {
    "\(self.file):\(self.line):\(self.column): \(self.kind): \(self.message)"
  }
}

extension FileCheckDiagnostic: Equatable {}
