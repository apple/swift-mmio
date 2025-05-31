//
//  File.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 5/30/25.
//


public protocol ParsablePrefix {
  static var prefix: String.UTF8View.SubSequence { get }
}

public struct PrefixParser2<Prefix>: Parser2 where Prefix: ParsablePrefix {
  public typealias Input = String.UTF8View.SubSequence
  public typealias Output = Void

  public static func parse(_ input: inout Input) -> Output? {
    guard input.starts(with: Prefix.prefix) else { return nil }
    input.removeFirst(Prefix.prefix.count)
    return ()
  }
}

public protocol ParsablePrefixUpTo {
  static var character: String.UTF8View.SubSequence.Element { get }
}

public struct PrefixUpToParser2<Prefix>: Parser2 where Prefix: ParsablePrefixUpTo {
  public typealias Input = String.UTF8View.SubSequence
  public typealias Output = String.UTF8View.SubSequence

  public static func parse(_ input: inout Input) -> Output? {
    let endIndex = input.firstIndex(of: Prefix.character) ?? input.endIndex
    let match = input[..<endIndex]
    input = input[endIndex...]
    return match
  }
}
