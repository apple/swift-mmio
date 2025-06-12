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

import XML

#if canImport(FoundationEssentials) && canImport(FoundationXML)
import FoundationEssentials
import FoundationXML
protocol NSObject {}
#else
import Foundation
#endif

enum BuilderState: ~Copyable {
  case initial
  case parsing(stack: [XMLElement])
  case error
  case complete(root: XMLElement)

  func dump() {
    switch self {
    case .initial:
      print("initial")
    case .parsing:
      print("parsing")
    case .error:
      print("error")
    case .complete:
      print("complete")
    }
  }

  mutating func start(name: String, attributes: [String: String]) {
    let node = XMLElement(name: name, attributes: attributes, children: [])
    switch consume self {
    case .initial:
      self = .parsing(stack: [node])
    case .parsing(var stack):
      stack.append(node)
      self = .parsing(stack: stack)
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func characters(text: String) {
    switch consume self {
    case .initial:
      self = .error
    case .parsing(var stack):
      if !stack.isEmpty {
        stack[stack.count - 1].value = text
        self = .parsing(stack: stack)
      } else {
        self = .error
      }
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func end(name: String) {
    switch consume self {
    case .initial:
      self = .error
    case .parsing(var stack):
      if let node = stack.last, node.name == name {
        stack.removeLast()
        if stack.isEmpty {
          self = .complete(root: node)
        } else {
          stack[stack.count - 1].children.append(node)
          self = .parsing(stack: stack)
        }
      } else {
        self = .error
      }
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func result() -> XMLElement? {
    switch consume self {
    case .initial:
      self = .error
      return nil
    case .parsing:
      self = .error
      return nil
    case .error:
      self = .error
      return nil
    case .complete(let root):
      self = .error
      return root
    }
  }
}

struct XMLParser2 {
  static func build(data: Data) -> XMLElement? {
    // Create the expat parser
    let parser = XML_ParserCreate("UTF-8")
    defer { XML_ParserFree(parser) }

    var state: BuilderState = .initial
    withUnsafeMutablePointer(to: &state) { statePointer in
      XML_SetUserData(parser, statePointer)
      defer { XML_SetUserData(parser, nil) }

      XML_SetStartElementHandler(parser, startElementHandler)
      XML_SetCharacterDataHandler(parser, characterDataHandler)
      XML_SetEndElementHandler(parser, endElementHandler)

      let result0 = data.withUnsafeBytes { bytes in
        XML_Parse(parser, bytes.baseAddress, Int32(bytes.count), Int32(XML_FALSE))
      }
      print("HELLO")
      statePointer.pointee.dump()
      if result0 == XML_STATUS_ERROR {
        statePointer.pointee = .error
      }

      let result1 = XML_Parse(parser, nil, 0, Int32(XML_TRUE))
      print("WORLD")
      statePointer.pointee.dump()
      if result1 != XML_STATUS_ERROR {
        statePointer.pointee = .error
      }
    }

    print("POST")
    state.dump()
    return state.result()
  }
}

fileprivate func startElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?,
  _attributes: UnsafeMutablePointer<UnsafePointer<XML_Char>?>?
) {
  guard let _context, let _name else { return }
  let context = _context.bindMemory(to: BuilderState.self, capacity: 1)
  let name = String(cString: _name)

  var attributes = [String: String]()
  var _attributes = _attributes
  while true {
    guard let _key = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)
    guard let _value = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)

    let key = String(cString: _key)
    let value = String(cString: _value)
    attributes[key] = value
  }

  context.pointee.start(name: name, attributes: attributes)
}

fileprivate func characterDataHandler(
  _context: UnsafeMutableRawPointer?,
  _characters: UnsafePointer<XML_Char>?,
  _count: Int32
) {
  guard let _context, let _characters else { return }
  let context = _context.bindMemory(to: BuilderState.self, capacity: 1)
  let characters = UnsafeBufferPointer(start: _characters, count: Int(_count))
  characters.withMemoryRebound(to: UInt8.self) { buffer in
    let characters = String(decoding: buffer, as: UTF8.self)
    context.pointee.characters(text: characters)
  }
}

fileprivate func endElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?
) {
  guard let _context, let _name else { return }
  let context = _context.bindMemory(to: BuilderState.self, capacity: 1)
  let name = String(cString: _name)
  context.pointee.end(name: name)
}

//final class XMLElementBuilder: NSObject {
//  static func build(data: Data) -> XMLElement? {
//    let parser = XMLParser(data: data)
//    let builder = XMLElementBuilder()
//    // parser.delegate = builder
//    guard parser.parse() else { return nil }
//    return builder.state.result()
//  }
//
//  var state: BuilderState
//
//  #if canImport(FoundationEssentials) && canImport(FoundationXML)
//  init() {
//    self.state = .initial
//  }
//  #else
//  override init() {
//    self.state = .initial
//    super.init()
//  }
//  #endif
//}
//
//extension XMLElementBuilder: XMLParserDelegate {
//  func parser(
//    _ parser: XMLParser,
//    didStartElement elementName: String,
//    namespaceURI: String?,
//    qualifiedName qName: String?,
//    attributes attributeDict: [String: String]
//  ) {
//    self.state.start(name: elementName, attributes: attributeDict)
//  }
//
//  func parser(
//    _ parser: XMLParser,
//    didEndElement elementName: String,
//    namespaceURI: String?,
//    qualifiedName qName: String?
//  ) {
//    self.state.end(name: elementName)
//  }
//
//  func parser(_ parser: XMLParser, foundCharacters characters: String) {
//    self.state.characters(text: characters)
//  }
//
//  func parser(_ parser: XMLParser, parseErrorOccurred error: any Error) {
//    self.state = .error
//  }
//
//  func parser(_ parser: XMLParser, validationErrorOccurred error: any Error) {
//    self.state = .error
//  }
//}
