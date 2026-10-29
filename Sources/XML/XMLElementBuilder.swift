//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public import Foundation
import MMIOUtilities
import XMLCore

private typealias State = XMLElementBuilderState

public struct XMLElementBuilder {
  public static func build(data: Data) -> XMLElement? {
    let parser = unsafe XML_ParserCreate("UTF-8")
    defer { unsafe XML_ParserFree(parser) }

    var state: State = .initial
    return withUnsafeMutablePointer(to: &state) { statePointer in
      unsafe XML_SetUserData(parser, statePointer)
      defer { unsafe XML_SetUserData(parser, nil) }

      unsafe XML_SetStartElementHandler(parser, startElementHandler)
      unsafe XML_SetCharacterDataHandler(parser, characterDataHandler)
      unsafe XML_SetEndElementHandler(parser, endElementHandler)

      let result = unsafe data.withUnsafeBytes { bytes in
        unsafe XML_Parse(
          parser, bytes.baseAddress, Int32(bytes.count), Int32(XML_TRUE))
      }
      if result == XML_STATUS_ERROR {
        unsafe statePointer.pointee = .error
      }

      return unsafe statePointer.pointee.result()
    }
  }
}

private func startElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?,
  _attributes: UnsafeMutablePointer<UnsafePointer<XML_Char>?>?
) {
  guard let _context = unsafe _context, let _name = unsafe _name else { return }
  let context = unsafe _context.bindMemory(to: State.self, capacity: 1)
  let name = unsafe String(cString: _name)

  var attributes = OwnedArray<(String, String)>()
  var _attributes = unsafe _attributes
  while true {
    guard let _key = unsafe _attributes?.pointee else { break }
    unsafe _attributes = _attributes?.advanced(by: 1)
    guard let _value = unsafe _attributes?.pointee else { break }
    unsafe _attributes = _attributes?.advanced(by: 1)

    let key = unsafe String(cString: _key)
    let value = unsafe String(cString: _value)
    attributes.push((key, value))
  }

  unsafe context.pointee.start(name: name, attributes: attributes)
}

private func characterDataHandler(
  _context: UnsafeMutableRawPointer?,
  _characters: UnsafePointer<XML_Char>?,
  _count: Int32
) {
  guard let _context = unsafe _context, let _characters = unsafe _characters
  else { return }
  let context = unsafe _context.bindMemory(to: State.self, capacity: 1)
  let count = Int(_count)

  let raw = unsafe UnsafeRawPointer(_characters)
  let typed = unsafe raw.bindMemory(to: UInt8.self, capacity: count)
  let buffer = unsafe UnsafeBufferPointer(start: typed, count: count)
  unsafe context.pointee.characters(text: buffer)
}

private func endElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?
) {
  guard let _context = unsafe _context, let _name = unsafe _name else { return }
  let context = unsafe _context.bindMemory(to: State.self, capacity: 1)
  let name = unsafe String(cString: _name)
  unsafe context.pointee.end(name: name)
}
