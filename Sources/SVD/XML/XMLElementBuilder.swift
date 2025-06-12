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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct OwnedArray<Element: ~Copyable>: ~Copyable {
  var buffer: UnsafeMutableBufferPointer<Element>?
  var capacity: Int { self.buffer?.count ?? 0 }
  var count: Int
  var isEmpty: Bool { self.count == 0 }
  var indices: Range<Int> { 0..<self.count }

  init() {
    self.buffer = nil
    self.count = 0
  }

  deinit {
    self.buffer?.extracting(..<self.count).deinitialize()
    self.buffer?.deallocate()
  }

  subscript(_ index: Int) -> Element {
    _read {
      guard index < self.count else {
        fatalError("Index out of range")
      }
      yield self.buffer![index]
    }
    _modify {
      guard index < self.count else {
        fatalError("Index out of range")
      }
      yield &self.buffer![index]
    }
  }

  

  mutating func push(_ value: consuming Element) {
    if self.count == self.capacity {
      if let oldBuffer = self.buffer {
        let newBuffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: oldBuffer.count * 2)
        _ = newBuffer.moveInitialize(fromContentsOf: oldBuffer)
        oldBuffer.deallocate()
        self.buffer = newBuffer
      } else {
        self.buffer = .allocate(capacity: 4)
      }
    }
    self.buffer?.initializeElement(at: self.count, to: value)
    self.count += 1
  }

  mutating func pop() -> Element? {
    guard self.count > 0 else { return nil }
    let element = self.buffer?.moveElement(from: self.count - 1)
    self.count -= 1
    return element
  }
}

enum BuilderState: ~Copyable {
  case initial
  case parsing(stack: OwnedArray<XMLElement>)
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
    let node = XMLElement(
      name: name,
      attributes: attributes,
      children: OwnedArray())
    switch consume self {
    case .initial:
      var stack = OwnedArray<XMLElement>()
      stack.push(node)
      self = .parsing(stack: stack)
    case .parsing(var stack):
      stack.push(node)
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
      if let node = stack.pop(), node.name == name {
        if stack.isEmpty {
          self = .complete(root: node)
        } else {
          stack[stack.count - 1].children.push(node)
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
    let parser = XML_ParserCreate("UTF-8")
    defer { XML_ParserFree(parser) }

    var state: BuilderState = .initial
    return withUnsafeMutablePointer(to: &state) { statePointer in
      XML_SetUserData(parser, statePointer)
      defer { XML_SetUserData(parser, nil) }

      XML_SetStartElementHandler(parser, startElementHandler)
      XML_SetCharacterDataHandler(parser, characterDataHandler)
      XML_SetEndElementHandler(parser, endElementHandler)

      let result0 = data.withUnsafeBytes { bytes in
        XML_Parse(parser, bytes.baseAddress, Int32(bytes.count), Int32(XML_FALSE))
      }
      if result0 == XML_STATUS_ERROR {
        statePointer.pointee = .error
      }

      let result1 = XML_Parse(parser, nil, 0, Int32(XML_TRUE))
      if result1 == XML_STATUS_ERROR {
        statePointer.pointee = .error
      }

      return statePointer.pointee.result()
    }
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
  let count = Int(_count)
  let buffer = UnsafeBufferPointer(start: _characters, count: count)
  let characters = buffer.withMemoryRebound(to: UInt8.self) { input in
    String(unsafeUninitializedCapacity: characters.count) { output in
      output.initialize(fromContentsOf: input)
    }



//    let characters = String(decoding: buffer, as: UTF8.self)
//    context.pointee.characters(text: characters)
  }
  context.pointee.characters(text: characters)
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
