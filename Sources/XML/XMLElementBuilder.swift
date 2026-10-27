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
    let parser = XML_ParserCreate("UTF-8")
    defer { XML_ParserFree(parser) }

    var state: State = .initial
    return withUnsafeMutablePointer(to: &state) { statePointer in
      XML_SetUserData(parser, statePointer)
      defer { XML_SetUserData(parser, nil) }

      XML_SetStartElementHandler(parser, startElementHandler)
      XML_SetCharacterDataHandler(parser, characterDataHandler)
      XML_SetEndElementHandler(parser, endElementHandler)

      let result = data.withUnsafeBytes { bytes in
        XML_Parse(
          parser, bytes.baseAddress, Int32(bytes.count), Int32(XML_TRUE))
      }
      if result == XML_STATUS_ERROR {
        statePointer.pointee = .error
      }

      return statePointer.pointee.result()
    }
  }
}

private func startElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?,
  _attributes: UnsafeMutablePointer<UnsafePointer<XML_Char>?>?
) {
  guard let _context, let _name else { return }
  let context = _context.bindMemory(to: State.self, capacity: 1)
  let name = String(cString: _name)

  var attributes = OwnedArray<(String, String)>()
  var _attributes = _attributes
  while true {
    guard let _key = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)
    guard let _value = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)

    let key = String(cString: _key)
    let value = String(cString: _value)
    attributes.push((key, value))
  }

  context.pointee.start(name: name, attributes: attributes)
}

private func characterDataHandler(
  _context: UnsafeMutableRawPointer?,
  _characters: UnsafePointer<XML_Char>?,
  _count: Int32
) {
  guard let _context, let _characters else { return }
  let context = _context.bindMemory(to: State.self, capacity: 1)
  let count = Int(_count)

  let raw = UnsafeRawPointer(_characters)
  let typed = raw.bindMemory(to: UInt8.self, capacity: count)
  let buffer = UnsafeBufferPointer(start: typed, count: count)
  context.pointee.characters(text: buffer)
}

private func endElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?
) {
  guard let _context, let _name else { return }
  let context = _context.bindMemory(to: State.self, capacity: 1)
  let name = String(cString: _name)
  context.pointee.end(name: name)
}
