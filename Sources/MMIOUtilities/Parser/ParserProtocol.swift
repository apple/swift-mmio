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

public enum Parser2 {

}

//extension String.UTF8View.SubSequence: @retroactive Equatable {
//  static public func == (lhs: Self, rhs: Self) -> Bool {
//    guard lhs.count == rhs.count else { return false }
//    return zip(lhs, rhs).allSatisfy(==)
//  }
//}


public protocol ParserProtocol<Input, Output> {
  associatedtype Input
  associatedtype Output

  func parse(_ input: inout Input) -> Output?
}

extension ParserProtocol where Input == String.UTF8View.SubSequence {
  public func parseAll(_ input: String) -> Output? {
    var input = input.utf8[...]
    guard let output = self.parse(&input), input.isEmpty else { return nil }
    return output
  }

//  static func parseAll(_ input: inout Input) -> Output? {
//    let original = input
//    if let output = Self.parse(&input), input.isEmpty {
//      return output
//    }
//    else {
//      input = original
//      return nil
//    }
//  }
}

extension ParserProtocol {
  public func skip<P: ParserProtocol>(_ p: P) -> some ParserProtocol<Input, Output>
  where P.Input == Input { Take0(p0: self, p1: p) }
}

extension ParserProtocol where Self.Output == Void {
  public func take<P: ParserProtocol>(_ p: P) -> some ParserProtocol<Input, P.Output>
  where P.Input == Input { Take1(p0: self, p1: p) }
}

extension ParserProtocol {
  public func take<P: ParserProtocol>(_ p: P) -> some ParserProtocol<Input, (Output, P.Output)>
  where P.Input == Input { Take01(p0: self, p1: p) }
}

fileprivate struct Take0<P0, P1>: ParserProtocol
where P0: ParserProtocol, P1: ParserProtocol, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = P0.Output

  var p0: P0
  var p1: P1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if let o0 = self.p0.parse(&input), let _ = self.p1.parse(&input) {
      return o0
    } else {
      input = original
      return nil
    }
  }
}

fileprivate struct Take1<P0, P1>: ParserProtocol
where P0: ParserProtocol, P1: ParserProtocol, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = P1.Output

  var p0: P0
  var p1: P1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if let _ = self.p0.parse(&input), let o1 = self.p1.parse(&input) {
      return o1
    } else {
      input = original
      return nil
    }
  }
}

fileprivate struct Take01<P0, P1>: ParserProtocol
where P0: ParserProtocol, P1: ParserProtocol, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = (P0.Output, P1.Output)

  var p0: P0
  var p1: P1

  func parse(_ input: inout Input) -> Output? {
    let original = input
    if let o0 = self.p0.parse(&input), let o1 = self.p1.parse(&input) {
      return (o0, o1)
    } else {
      input = original
      return nil
    }
  }
}


// MARK: - Strings


// MARK: - Numbers



protocol OneOfParsable<Input> {
  associatedtype Input
  static var needle: Input { get }
}

struct OneOfParser2<Input, Output>: Parser2
where Output: CaseIterable, Output: OneOfParsable, Output.Input == Input {
  

  func parse(_ input: inout Input) -> Output? {
    for `case` in Output.allCases {
      let prefix = `case`.needle[...]
      if input.starts(with: prefix) {
        input.removeFirst(prefix.count)
        return `case`
      }
    }
    return nil
  }
}

public static func cases(_: Output.Type = Output.self) -> Self
where Output: CaseIterable & RawRepresentable, Output.RawValue == String {
  Self { input in
    for `case` in Output.allCases {
      let prefix = `case`.rawValue[...]
      if input.starts(with: prefix) {
        input.removeFirst(prefix.count)
        return `case`
      }
    }
    return nil
  }
}



