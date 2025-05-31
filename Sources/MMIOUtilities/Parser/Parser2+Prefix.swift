//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Parser2 {
  public static func prefix(
    _ prefix: String
  ) -> some ParserProtocol<String.UTF8View.SubSequence, Void> {
    PrefixParser2(prefix: prefix.utf8[...])
  }
}

fileprivate struct PrefixParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = Void

  var prefix: Input

  func parse(_ input: inout Input) -> Output? {
    guard input.starts(with: self.prefix) else { return nil }
    input.removeFirst(self.prefix.count)
    return ()
  }
}

public struct PrefixUpToParser2<Prefix>: ParserProtocol {
  public typealias Input = String.UTF8View.SubSequence
  public typealias Output = String.UTF8View.SubSequence

  var prefix: Input

  public func parse(_ input: inout Input) -> Output? {
    let endIndex = input.firstIndex(of: self.prefix.first!) ?? input.endIndex
    let match = input[..<endIndex]
    input = input[endIndex...]
    return match
  }
}
