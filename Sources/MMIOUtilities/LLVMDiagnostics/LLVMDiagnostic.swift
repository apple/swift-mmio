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

public struct LLVMDiagnostic {
  public var file: String
  public var line: Int
  public var column: Int
  public var kind: LLVMDiagnosticKind
  public var message: String

  public init(
    file: String,
    line: Int,
    column: Int,
    kind: LLVMDiagnosticKind,
    message: String
  ) {
    self.file = file
    self.line = line
    self.column = column
    self.kind = kind
    self.message = message
  }
}

extension LLVMDiagnostic: CustomStringConvertible {
  public var description: String {
    "\(self.file):\(self.line):\(self.column): \(self.kind): \(self.message)"
  }
}

extension LLVMDiagnostic: Equatable {}

extension LLVMDiagnostic: Sendable {}
