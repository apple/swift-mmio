//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public import Foundation
import MMIOUtilities
import XMLCore

/// Decodes values from XML data while expat parses the data.
///
/// The decoder keeps a stack of frames, one for each open element that a
/// builder decodes. When an element ends, its frame stores the value in a
/// slot of the parent builder. The decoder skips the elements that no
/// builder decodes.
public enum XMLDecoder {
  @inlinable
  public static func decode<Value>(
    _: Value.Type = Value.self,
    from data: Data
  ) throws -> Value where Value: XMLElementDecodable {
    var root = XMLSlot<Value>()
    try withUnsafeMutablePointer(to: &root) { root in
      let destination = XMLDestination(root)
      try Self.parse(
        data, root: XMLFrame(element: Value.self, into: destination))
    }
    do throws(XMLBuildError) {
      return try root.required("root element")
    } catch {
      throw error.error
    }
  }

  @usableFromInline
  static func parse(_ data: Data, root: XMLFrame) throws {
    let parser = XML_ParserCreate("UTF-8")
    defer { XML_ParserFree(parser) }

    var state = XMLDecoderState(parser: parser, root: root)
    try withUnsafeMutablePointer(to: &state) { state in
      XML_SetUserData(parser, state)
      defer { XML_SetUserData(parser, nil) }

      XML_SetStartElementHandler(parser, startElementHandler)
      XML_SetEndElementHandler(parser, endElementHandler)

      let result = data.withUnsafeBytes { bytes in
        XML_Parse(
          parser, bytes.baseAddress, Int32(bytes.count), Int32(XML_TRUE))
      }
      guard result == XML_STATUS_OK else {
        state.pointee.cancel()
        let code = XML_GetErrorCode(parser)
        let message = XML_ErrorString(code).map { String(cString: $0) }
        let line = XML_GetCurrentLineNumber(parser)
        throw XMLError.invalidDocument(
          "\(message ?? "unknown error") at line \(line)")
      }
    }
  }
}

struct XMLDecoderState {
  var parser: XML_Parser?
  /// The frame of the root element, until the root element starts.
  var root: XMLFrame?
  /// The frames of the open elements that the decoder decodes.
  var frames: [XMLFrame] = []
  /// The number of open elements that the decoder skips.
  var skipDepth = 0
  /// The text of the open element that decodes from its text.
  ///
  /// The text is empty if the element has only white space.
  var text: [UInt8] = []
  /// White space that is not yet part of the text.
  var space: [UInt8] = []

  init(parser: XML_Parser?, root: XMLFrame) {
    self.parser = parser
    self.root = root
  }

  /// Starts an element, and returns its frame if the decoder decodes it.
  mutating func start(_ name: XMLName) -> XMLFrame? {
    guard self.skipDepth == 0 else {
      self.skipDepth += 1
      return nil
    }

    var frame: XMLFrame? = nil
    if let root = self.root {
      self.root = nil
      frame = root
    } else if let parent = self.frames.last,
      case .element(let builderType, let builder) = parent.decoder
    {
      frame = builderType._handle(
        .child(name), builder: builder, destination: parent.destination)
    }

    guard let frame else {
      // The decoder skips the children of an element that decodes from its
      // text, but the white space before a child is part of the text.
      self.appendSpace()
      self.skipDepth = 1
      return nil
    }
    self.text.removeAll(keepingCapacity: true)
    self.space.removeAll(keepingCapacity: true)
    self.frames.append(frame)
    if case .value = frame.decoder {
      // Only elements that decode from their text need the text. Expat does
      // not report text when no handler is set, for example the white space
      // between the children of an element.
      XML_SetCharacterDataHandler(self.parser, characterDataHandler)
    }
    return frame
  }

  /// Adds a part of the text of the open element.
  ///
  /// Expat can split the text of an element into many parts, for example at
  /// line ends and at references.
  mutating func characters(_ text: UnsafeBufferPointer<UInt8>) {
    guard
      self.skipDepth == 0,
      let frame = self.frames.last,
      case .value = frame.decoder
    else { return }
    if text.allSatisfy(\.isWhiteSpace) {
      self.space.append(contentsOf: text)
    } else {
      self.text.append(contentsOf: self.space)
      self.space.removeAll(keepingCapacity: true)
      self.text.append(contentsOf: text)
    }
  }

  /// Adds the white space to the text, if the text is not empty.
  mutating func appendSpace() {
    if !self.text.isEmpty {
      self.text.append(contentsOf: self.space)
    }
    self.space.removeAll(keepingCapacity: true)
  }

  mutating func end() {
    guard self.skipDepth == 0 else {
      self.skipDepth -= 1
      return
    }
    let frame = self.frames.removeLast()
    switch frame.decoder {
    case .value(let valueType):
      XML_SetCharacterDataHandler(self.parser, nil)
      self.appendSpace()
      self.text.withUnsafeBufferPointer { text in
        valueType._decode(XMLText(bytes: text), into: frame.destination)
      }
    case .element(let builderType, let builder):
      _ = builderType._handle(
        .end, builder: builder, destination: frame.destination)
    }
  }

  /// Frees the builders of all frames after an error.
  mutating func cancel() {
    var frames = self.frames
    if let root = self.root {
      frames.append(root)
    }
    for frame in frames {
      guard case .element(let builderType, let builder) = frame.decoder
      else { continue }
      _ = builderType._handle(
        .cancel, builder: builder, destination: frame.destination)
    }
    self.frames = []
    self.root = nil
  }
}

private func bytes(
  _ cString: UnsafePointer<XML_Char>
) -> UnsafeBufferPointer<UInt8> {
  let count = strlen(cString)
  let raw = UnsafeRawPointer(cString)
  let typed = raw.bindMemory(to: UInt8.self, capacity: count)
  return UnsafeBufferPointer(start: typed, count: count)
}

private func startElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?,
  _attributes: UnsafeMutablePointer<UnsafePointer<XML_Char>?>?
) {
  guard let _context, let _name else { return }
  let context = _context.bindMemory(to: XMLDecoderState.self, capacity: 1)
  let name = XMLName(bytes: bytes(_name))
  guard
    let frame = context.pointee.start(name),
    case .element(let builderType, let builder) = frame.decoder
  else { return }

  var _attributes = _attributes
  while true {
    guard let _key = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)
    guard let _value = _attributes?.pointee else { break }
    _attributes = _attributes?.advanced(by: 1)
    let name = XMLName(bytes: bytes(_key))
    let value = XMLText(bytes: bytes(_value))
    _ = builderType._handle(
      .attribute(name, value), builder: builder,
      destination: frame.destination)
  }
}

private func characterDataHandler(
  _context: UnsafeMutableRawPointer?,
  _characters: UnsafePointer<XML_Char>?,
  _count: Int32
) {
  guard let _context, let _characters else { return }
  let context = _context.bindMemory(to: XMLDecoderState.self, capacity: 1)
  let count = Int(_count)

  let raw = UnsafeRawPointer(_characters)
  let typed = raw.bindMemory(to: UInt8.self, capacity: count)
  context.pointee.characters(UnsafeBufferPointer(start: typed, count: count))
}

private func endElementHandler(
  _context: UnsafeMutableRawPointer?,
  _name: UnsafePointer<XML_Char>?
) {
  guard let _context else { return }
  let context = _context.bindMemory(to: XMLDecoderState.self, capacity: 1)
  context.pointee.end()
}
