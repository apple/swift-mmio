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

public enum LLVMDiagnosticKind: String {
  case error
  case warning
  case note
}

extension LLVMDiagnosticKind: CaseIterable {}

extension LLVMDiagnosticKind: Equatable {}

extension LLVMDiagnosticKind: Sendable {}
