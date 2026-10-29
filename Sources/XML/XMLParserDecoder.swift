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
public import NewCodable

/// A `CommonDecoder` that decodes values while it reads XML.
///
/// An element decodes as a struct. Its fields are its attributes, with the
/// prefix `@`, followed by its child elements in document order. A leaf
/// element decodes as the value of its text.
@safe
public struct XMLParserDecoder: CommonDecoder {
  @usableFromInline let reader: UnsafeMutablePointer<XMLReader>
  /// The value range of the attribute that this decoder reads, or `nil` if
  /// it reads the open element.
  @usableFromInline let attribute: (start: Int, count: Int)?

  @inlinable
  init(
    reader: UnsafeMutablePointer<XMLReader>,
    attribute: (start: Int, count: Int)? = nil
  ) {
    unsafe self.reader = reader
    self.attribute = attribute
  }

  public var codingPath: CodingPath { CodingPath([]) }

  /// Decodes a value from the root element of an XML document.
  @inlinable
  public static func decode<T: CommonDecodable>(
    _: T.Type, from data: Data
  ) throws -> T {
    try unsafe data.withUnsafeBytes { bytes throws in
      let base = unsafe bytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
      guard let base = unsafe base else {
        throw XMLSyntaxError(offset: 0, message: "missing root element")
      }
      // The reader works on bytes, so check the encoding of the whole
      // document first.
      let span = unsafe UnsafeBufferPointer(start: base, count: bytes.count)
        .span
      do throws(UTF8.ValidationError) {
        _ = try UTF8Span(validating: span)
      } catch {
        throw XMLSyntaxError(
          offset: error.byteOffsets.lowerBound, message: "invalid UTF-8")
      }
      var reader = unsafe XMLReader(base: base, count: bytes.count)
      return try withUnsafeMutablePointer(to: &reader) { reader throws in
        try unsafe reader.pointee.readRoot()
        var decoder = unsafe XMLParserDecoder(reader: reader)
        defer { unsafe reader.pointee.deallocate() }
        let value = try T.decode(from: &decoder)
        try unsafe reader.pointee.skip(toDepth: 0)
        try unsafe reader.pointee.readEpilog()
        return value
      }
    }
  }

  @inlinable
  static func wrap(_ error: XMLSyntaxError) -> CodingError.Decoding {
    CodingError.dataCorrupted(debugDescription: error.description)
  }

  // MARK: Struct

  @safe
  public struct StructDecoder: CommonStructDecoder {
    public typealias FieldDecoder = XMLParserDecoder.FieldDecoder
    public typealias ValueDecoder = XMLParserDecoder

    @usableFromInline let reader: UnsafeMutablePointer<XMLReader>

    @inlinable
    init(reader: UnsafeMutablePointer<XMLReader>) {
      unsafe self.reader = reader
    }

    public var codingPath: CodingPath { CodingPath([]) }

    @inlinable
    public mutating func decodeExpectedOrderField(
      required: Bool, matchingClosure: (UTF8Span) -> Bool,
      andValue valueDecoderClosure:
        (inout ValueDecoder) throws(CodingError.Decoding) -> Void
    ) throws(CodingError.Decoding) -> Bool {
      throw CodingError.unsupportedDecodingType("ordered XML fields")
    }

    @inlinable
    public mutating func decodeEachField(
      _ fieldDecoderClosure:
        (inout FieldDecoder) throws(CodingError.Decoding) -> Void,
      andValue valueDecoderClosure:
        (inout ValueDecoder) throws(CodingError.Decoding) -> Void
    ) throws(CodingError.Decoding) {
      let reader = unsafe self.reader
      // Attributes come first. Reading an attribute value does not move the
      // reader, so the attribute ranges stay valid until the first child.
      let attributeCount = unsafe reader.pointee.attributes.count
      var index = 0
      while index < attributeCount {
        let attribute = unsafe reader.pointee.attributes[index]
        var field = unsafe FieldDecoder(
          base: reader.pointee.base + attribute.nameStart,
          count: attribute.nameCount, isAttribute: true)
        try fieldDecoderClosure(&field)
        var value = unsafe XMLParserDecoder(
          reader: reader,
          attribute: (attribute.valueStart, attribute.valueCount))
        try valueDecoderClosure(&value)
        index += 1
      }

      let depth = unsafe reader.pointee.depth
      while true {
        let isChild: Bool
        do throws(XMLSyntaxError) {
          isChild = try unsafe reader.pointee.nextChild()
        } catch {
          throw XMLParserDecoder.wrap(error)
        }
        guard isChild else { return }
        let name = unsafe reader.pointee.stack[depth]
        var field = unsafe FieldDecoder(
          base: reader.pointee.base + name.start, count: name.count,
          isAttribute: false)
        try fieldDecoderClosure(&field)
        var value = unsafe XMLParserDecoder(reader: reader)
        try valueDecoderClosure(&value)
        // Skip the rest of the child if the value did not read all of it.
        do throws(XMLSyntaxError) {
          try unsafe reader.pointee.skip(toDepth: depth)
        } catch {
          throw XMLParserDecoder.wrap(error)
        }
      }
    }

    @inlinable
    public mutating func decodeEachKeyAndValue(
      _ closure: (String, inout ValueDecoder) throws(CodingError.Decoding)
        -> Bool
    ) throws(CodingError.Decoding) {
      throw CodingError.unsupportedDecodingType("XML keys")
    }
  }

  @safe
  public struct FieldDecoder: CommonFieldDecoder {
    @usableFromInline let base: UnsafePointer<UInt8>
    @usableFromInline let count: Int
    @usableFromInline let isAttribute: Bool

    @inlinable
    init(base: UnsafePointer<UInt8>, count: Int, isAttribute: Bool) {
      unsafe self.base = base
      self.count = count
      self.isAttribute = isAttribute
    }

    /// Returns `true` if the field has the name `key`.
    ///
    /// An attribute name has the prefix `@`.
    @inlinable @inline(__always)
    public func matches(_ key: StaticString) -> Bool {
      let keyCount = key.utf8CodeUnitCount
      if self.isAttribute {
        return unsafe keyCount == self.count + 1
          && key.utf8Start[0] == UInt8(ascii: "@")
          && memcmp(key.utf8Start + 1, self.base, self.count) == 0
      }
      return unsafe keyCount == self.count
        && memcmp(key.utf8Start, self.base, self.count) == 0
    }

    @inlinable
    public func matches(_ field: some DecodingField) -> Bool {
      // TODO: attribute names
      let span = unsafe UnsafeBufferPointer(start: self.base, count: self.count)
        .span
      guard let utf8 = try? UTF8Span(validating: span) else { return false }
      return field.matches(utf8)
    }

    @inlinable
    public func decode<T: DecodingField>(
      _: T.Type
    ) throws(CodingError.Decoding) -> T {
      let span = unsafe UnsafeBufferPointer(start: self.base, count: self.count)
        .span
      let utf8: UTF8Span
      do {
        utf8 = try UTF8Span(validating: span)
      } catch {
        throw CodingError.dataCorrupted(debugDescription: "invalid UTF-8")
      }
      return try T.field(for: utf8)
    }
  }

  // MARK: Unsupported containers

  public struct UnsupportedDecoder: CommonDictionaryDecoder, CommonArrayDecoder
  {
    public typealias KeyDecoder = XMLParserDecoder
    public typealias ValueDecoder = XMLParserDecoder
    public typealias ElementDecoder = XMLParserDecoder

    public var codingPath: CodingPath { CodingPath([]) }

    public mutating func decodeEachKey(
      _ keyDecodingClosure:
        (inout KeyDecoder) throws(CodingError.Decoding) -> Void,
      andValue valueDecoderClosure:
        (inout ValueDecoder) throws(CodingError.Decoding) -> Void
    ) throws(CodingError.Decoding) {
      throw CodingError.unsupportedDecodingType("dictionary")
    }

    public mutating func decodeKey(
      _ keyDecodingClosure:
        (inout KeyDecoder) throws(CodingError.Decoding) -> Void,
      andValue valueDecoderClosure:
        (inout ValueDecoder) throws(CodingError.Decoding) -> Void
    ) throws(CodingError.Decoding) -> Bool {
      throw CodingError.unsupportedDecodingType("dictionary")
    }

    public mutating func decodeNext<T: ~Copyable>(
      _ closure: (inout ElementDecoder) throws(CodingError.Decoding) -> T
    ) throws(CodingError.Decoding) -> T? {
      throw CodingError.unsupportedDecodingType("array")
    }

    public mutating func decodeEachElement(
      _ closure: (inout ElementDecoder) throws(CodingError.Decoding) -> Void
    ) throws(CodingError.Decoding) {
      throw CodingError.unsupportedDecodingType("array")
    }
  }

  public typealias DictionaryDecoder = UnsupportedDecoder
  public typealias ArrayDecoder = UnsupportedDecoder

  // MARK: Values

  @inlinable
  public mutating func decodeStruct<T: ~Copyable>(
    _ closure: (inout StructDecoder) throws(CodingError.Decoding) -> T
  ) throws(CodingError.Decoding) -> T {
    guard self.attribute == nil else {
      throw CodingError.unsupportedDecodingType("struct in an attribute")
    }
    var decoder = unsafe StructDecoder(reader: self.reader)
    return try closure(&decoder)
  }

  /// Returns the text of the attribute or element.
  ///
  /// The result is valid until the next call to the reader.
  @inlinable
  mutating func text() throws(CodingError.Decoding) -> UnsafeBufferPointer<
    UInt8
  > {
    do throws(XMLSyntaxError) {
      if let attribute = self.attribute {
        return try unsafe self.reader.pointee.attributeValue(
          start: attribute.start, count: attribute.count)
      }
      return try unsafe self.reader.pointee.readText()
    } catch {
      throw XMLParserDecoder.wrap(error)
    }
  }

  @inlinable
  public mutating func decode(_: String.Type) throws(CodingError.Decoding)
    -> String
  {
    unsafe String(decoding: try self.text(), as: UTF8.self)
  }

  @inlinable
  public mutating func decodeString<V: DecodingStringVisitor & ~Copyable>(
    _ visitor: borrowing V
  ) throws(CodingError.Decoding) -> V.DecodedValue {
    let text = try unsafe self.text()
    let utf8: UTF8Span
    do {
      utf8 = try unsafe UTF8Span(validating: text.span)
    } catch {
      throw CodingError.dataCorrupted(debugDescription: "Invalid UTF-8")
    }
    return try visitor.visitUTF8Bytes(utf8)
  }

  /// Decodes `1`, `true`, `0`, or `false`.
  @inlinable
  public mutating func decode(_: Bool.Type) throws(CodingError.Decoding)
    -> Bool
  {
    let text = try unsafe self.text()
    switch text.count {
    case 1 where unsafe text[0] == UInt8(ascii: "1"): return true
    case 1 where unsafe text[0] == UInt8(ascii: "0"): return false
    case 4
    where unsafe memcmp(text.baseAddress.unsafelyUnwrapped, "true", 4) == 0:
      return true
    case 5
    where unsafe memcmp(text.baseAddress.unsafelyUnwrapped, "false", 5) == 0:
      return false
    default:
      throw CodingError.dataCorrupted(
        debugDescription:
          unsafe "Invalid boolean '\(String(decoding: text, as: UTF8.self))'")
    }
  }

  /// Decodes an SVD `scaledNonNegativeInteger`.
  @inlinable
  public mutating func decode(_: UInt64.Type) throws(CodingError.Decoding)
    -> UInt64
  {
    let text = try unsafe self.text()
    guard let value = unsafe parseScaledNonNegativeInteger(text) else {
      throw CodingError.dataCorrupted(
        debugDescription:
          unsafe "Invalid integer '\(String(decoding: text, as: UTF8.self))'")
    }
    return value
  }
}

/// Parses `[+]?(0x|0X|#)?[0-9a-fA-F]+[kmgtKMGT]?`.
@usableFromInline
func parseScaledNonNegativeInteger(
  _ text: UnsafeBufferPointer<UInt8>
) -> UInt64? {
  var index = 0
  let count = text.count
  if index < count, unsafe text[index] == UInt8(ascii: "+") { index += 1 }
  var base: UInt64 = 10
  if index < count, unsafe text[index] == UInt8(ascii: "#") {
    index += 1
    base = 2
  } else if index + 1 < count, unsafe text[index] == UInt8(ascii: "0"),
    unsafe text[index + 1] == UInt8(ascii: "x")
      || text[index + 1] == UInt8(ascii: "X")
  {
    index += 2
    base = 16
  }

  var value: UInt64 = 0
  let digitsStart = index
  while index < count {
    let byte = unsafe text[index]
    let digit: UInt64
    switch byte {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      digit = UInt64(byte - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      digit = UInt64(byte - UInt8(ascii: "a") + 10)
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      digit = UInt64(byte - UInt8(ascii: "A") + 10)
    default:
      digit = .max
    }
    guard digit < base else { break }
    let (product, overflow1) = value.multipliedReportingOverflow(by: base)
    let (sum, overflow2) = product.addingReportingOverflow(digit)
    guard !overflow1, !overflow2 else { return nil }
    value = sum
    index += 1
  }
  guard index > digitsStart else { return nil }
  guard index < count else { return value }

  let scale: UInt64
  switch unsafe text[index] {
  case UInt8(ascii: "k"), UInt8(ascii: "K"): scale = 1_000
  case UInt8(ascii: "m"), UInt8(ascii: "M"): scale = 1_000_000
  case UInt8(ascii: "g"), UInt8(ascii: "G"): scale = 1_000_000_000
  case UInt8(ascii: "t"), UInt8(ascii: "T"): scale = 1_000_000_000_000
  default: return nil
  }
  guard index + 1 == count else { return nil }
  let (scaled, overflow) = value.multipliedReportingOverflow(by: scale)
  return overflow ? nil : scaled
}
