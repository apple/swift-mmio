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

struct CollectUpToParser: ParserProtocol {
  typealias Output = String.UTF8View.SubSequence

  var character: Output.Element

  init(_ character: String) {
    var character = character.utf8[...]
    precondition(character.count == 1)
    self.character = character.removeFirst()
  }

  func parse(_ input: inout Input) -> Output? {
    let endIndex = input.firstIndex(of: self.character) ?? input.endIndex
    let match = input[..<endIndex]
    input = input[endIndex...]
    return match
  }
}

public struct DropParser: ParserProtocol {
  public typealias Output = Void

  var prefix: Input

  public init(_ prefix: String) {
    self.prefix = prefix.utf8[...]
  }

  public func parse(_ input: inout Input) -> Output? {
    guard input.starts(with: self.prefix) else { return nil }
    input.removeFirst(self.prefix.count)
    return ()
  }
}
