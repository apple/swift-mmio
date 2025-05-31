// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol Parser2<Input, Output> {
  associatedtype Input
  associatedtype Output

  static func parse(_ input: inout Input) -> Output?
}

extension Parser2 where Input == String.UTF8View.SubSequence {
  public static func parser() -> Parser<Input, Output> {
    Parser<Input, Output> { input in
      Self.parse(&input)
    }
  }
}


public struct BaseParser2<Input>: Parser2 {
  public typealias Output = Void
  public static func parse(_ input: inout Input) -> Output? { () }
}

extension Parser2 where Self.Output == Void {
  public static func take<P: Parser2>(_ p: P.Type) -> (some Parser2<Input, P.Output>).Type
  where P.Input == Input { Take1<Self, P>.self }
}

extension Parser2 {
  public static func skip<P: Parser2>(_ p: P.Type) -> (some Parser2<Input, Output>).Type
  where P.Input == Input { Take0<Self, P>.self }
}

struct Take0<P0, P1>: Parser2
where P0: Parser2, P1: Parser2, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = P0.Output

  static func parse(_ input: inout Input) -> Output? {
    let original = input
    if let o0 = P0.parse(&input), let _ = P1.parse(&input) {
      return o0
    } else {
      input = original
      return nil
    }
  }
}

struct Take1<P0, P1>: Parser2
where P0: Parser2, P1: Parser2, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = P1.Output

  static func parse(_ input: inout Input) -> Output? {
    let original = input
    if let _ = P0.parse(&input), let o1 = P1.parse(&input) {
      return o1
    } else {
      input = original
      return nil
    }
  }
}

extension Parser2 {
  public func take<P: Parser2>(_ p: P.Type) -> (some Parser2<Input, (Output, P.Output)>).Type
  where P.Input == Input { Take01<Self, P>.self }
}

struct Take01<P0, P1>: Parser2
where P0: Parser2, P1: Parser2, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = (P0.Output, P1.Output)

  var p0: P0
  var p1: P1

  init(_ p0: P0, _ p1: P1) {
    self.p0 = p0
    self.p1 = p1
  }

  static func parse(_ input: inout Input) -> Output? {
    let original = input
    if let o0 = P0.parse(&input), let o1 = P1.parse(&input) {
      return (o0, o1)
    } else {
      input = original
      return nil
    }
  }
}


// MARK: - Strings

extension Parser2 where Input == String.UTF8View.SubSequence {
  public static func parseAll(_ input: String) -> Output? {
    var input = input.utf8[...]
    guard let output = Self.parse(&input), input.isEmpty else { return nil }
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

// MARK: - Numbers


extension String.UTF8View.SubSequence: @retroactive Equatable {
  static public func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy(==)
  }
}

//protocol OneOfParsable<Input> {
//  associatedtype Input
//  static var needle: Input { get }
//}
//
//struct OneOfParser2<Input, Output>: Parser2
//where Output: CaseIterable, Output: OneOfParsable, Output.Input == Input {
//  static func parse(_ input: inout Input) -> Output? {
//    for `case` in Output.allCases {
//      let prefix = `case`.needle[...]
//      if input.starts(with: prefix) {
//        input.removeFirst(prefix.count)
//        return `case`
//      }
//    }
//    return nil
//  }
//}

//public static func cases(_: Output.Type = Output.self) -> Self
//where Output: CaseIterable & RawRepresentable, Output.RawValue == String {
//  Self { input in
//    for `case` in Output.allCases {
//      let prefix = `case`.rawValue[...]
//      if input.starts(with: prefix) {
//        input.removeFirst(prefix.count)
//        return `case`
//      }
//    }
//    return nil
//  }
//}
//
//




