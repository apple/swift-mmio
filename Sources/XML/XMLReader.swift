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

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// The byte range of one attribute in the last start tag.
@usableFromInline
struct XMLAttributeRange: BitwiseCopyable {
  @usableFromInline var nameStart: Int
  @usableFromInline var nameCount: Int
  @usableFromInline var valueStart: Int
  @usableFromInline var valueCount: Int
}

/// A growable buffer of trivial values that the reader owns.
@usableFromInline
@unsafe
struct XMLBuffer<Element: BitwiseCopyable> {
  @usableFromInline var base: UnsafeMutablePointer<Element>
  @usableFromInline var count = 0
  @usableFromInline var capacity: Int

  @usableFromInline
  init(capacity: Int) {
    unsafe self.base = .allocate(capacity: capacity)
    unsafe self.capacity = capacity
  }

  @usableFromInline
  func deallocate() { unsafe self.base.deallocate() }

  @inline(__always) @usableFromInline
  subscript(_ index: Int) -> Element {
    get { unsafe self.base[index] }
    nonmutating set { unsafe self.base[index] = newValue }
  }

  @inline(__always) @usableFromInline
  mutating func append(_ element: Element) {
    if unsafe self.count == self.capacity {
      unsafe self.grow(minimum: self.count + 1)
    }
    unsafe self.base[self.count] = element
    unsafe self.count += 1
  }

  @inline(__always) @usableFromInline
  mutating func append(_ elements: UnsafePointer<Element>, count: Int) {
    if unsafe self.count + count > self.capacity {
      unsafe self.grow(minimum: self.count + count)
    }
    unsafe (self.base + self.count).update(from: elements, count: count)
    unsafe self.count += count
  }

  @usableFromInline
  mutating func grow(minimum: Int) {
    let capacity = unsafe max(self.capacity * 2, minimum)
    let base = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
    unsafe base.update(from: self.base, count: self.count)
    unsafe self.base.deallocate()
    unsafe self.base = base
    unsafe self.capacity = capacity
  }

  @usableFromInline
  var buffer: UnsafeBufferPointer<Element> {
    unsafe UnsafeBufferPointer(start: self.base, count: self.count)
  }
}

/// The error that the reader throws for input that is not well formed.
public struct XMLSyntaxError: Error, CustomStringConvertible {
  public var offset: Int
  public var message: String
  public var description: String {
    "XML syntax error at byte \(offset): \(message)"
  }

  @usableFromInline
  init(offset: Int, message: String) {
    self.offset = offset
    self.message = message
  }
}

/// A pull reader over UTF-8 XML bytes.
///
/// The reader keeps a stack of the open elements. The decoder asks it for the
/// next child of the open element, for the text of the open element, or to
/// skip the rest of an element.
@usableFromInline
@unsafe
struct XMLReader {
  @usableFromInline let base: UnsafePointer<UInt8>
  @usableFromInline let count: Int
  @usableFromInline var position: Int = 0
  /// The name ranges of the open elements.
  @usableFromInline var stack = unsafe XMLBuffer<(start: Int, count: Int)>(
    capacity: 32)
  /// The attributes of the last start tag.
  @usableFromInline var attributes = unsafe XMLBuffer<XMLAttributeRange>(
    capacity: 8)
  /// The last start tag was `<name/>`.
  ///
  /// Its element is open, but it has no content.
  @usableFromInline var emptyElement = false
  /// Text with references replaced.
  @usableFromInline var scratch = unsafe XMLBuffer<UInt8>(capacity: 256)

  @usableFromInline
  init(base: UnsafePointer<UInt8>, count: Int) {
    unsafe self.base = base
    unsafe self.count = count
  }

  @usableFromInline
  func deallocate() {
    unsafe self.stack.deallocate()
    unsafe self.attributes.deallocate()
    unsafe self.scratch.deallocate()
  }

  @usableFromInline
  var depth: Int { unsafe self.stack.count }

  @inline(__always) @usableFromInline
  subscript(_ offset: Int) -> UInt8 { unsafe self.base[offset] }

  @usableFromInline
  func error(_ message: String) -> XMLSyntaxError {
    unsafe XMLSyntaxError(offset: self.position, message: message)
  }

  // MARK: - Low level scanning

  /// Returns the offset of the next `byte` at or after `from`, or `count`.
  @inline(__always) @usableFromInline
  func find(_ byte: UInt8, from: Int) -> Int {
    guard unsafe from < self.count else { return unsafe self.count }
    let found = unsafe memchr(self.base + from, Int32(byte), self.count - from)
    guard let found = unsafe found else { return unsafe self.count }
    return unsafe self.base.distance(
      to: found.assumingMemoryBound(to: UInt8.self))
  }

  @inline(__always) @usableFromInline
  static func isSpace(_ byte: UInt8) -> Bool {
    byte == 0x20 || byte == 0x0A || byte == 0x09 || byte == 0x0D
  }

  /// Returns `true` if a name can start with `byte`.
  ///
  /// The reader checks only the first byte of a name.
  @inline(__always) @usableFromInline
  static func isNameStart(_ byte: UInt8) -> Bool {
    switch byte {
    case UInt8(ascii: "a")...UInt8(ascii: "z"),
      UInt8(ascii: "A")...UInt8(ascii: "Z"),
      UInt8(ascii: "_"), UInt8(ascii: ":"), 0x80...0xFF:
      true
    default: false
    }
  }

  @inline(__always) @usableFromInline
  static func isNameEnd(_ byte: UInt8) -> Bool {
    switch byte {
    case 0x00...0x20, UInt8(ascii: "/"), UInt8(ascii: ">"), UInt8(ascii: "="):
      true
    default: false
    }
  }

  /// Returns the offset of the first byte at or after `from` that ends a
  /// name, or `count`.
  @inline(__always) @usableFromInline
  func findNameEnd(from: Int) -> Int {
    // Test eight bytes at a time for a control or space byte, `/`, `>`, or
    // `=`.
    let ones: UInt64 = 0x0101_0101_0101_0101
    let highs: UInt64 = 0x8080_8080_8080_8080
    var offset = from
    while unsafe offset + 8 <= self.count {
      let word = unsafe UnsafeRawPointer(self.base + offset).loadUnaligned(
        as: UInt64.self)
      let slash = word ^ (ones &* UInt64(UInt8(ascii: "/")))
      let gt = word ^ (ones &* UInt64(UInt8(ascii: ">")))
      let eq = word ^ (ones &* UInt64(UInt8(ascii: "=")))
      // Bytes less than 0x21 that are not 0x80 or more.
      let low = (word &- ones &* 0x21) & ~word
      let zero =
        low | ((slash &- ones) & ~slash) | ((gt &- ones) & ~gt)
        | ((eq &- ones) & ~eq)
      let found = zero & highs
      if found != 0 {
        return offset + found.trailingZeroBitCount / 8
      }
      offset += 8
    }
    while unsafe offset < self.count, unsafe !Self.isNameEnd(self[offset]) {
      offset += 1
    }
    return offset
  }

  @inline(__always) @usableFromInline
  mutating func skipSpace() {
    while unsafe self.position < self.count,
      unsafe Self.isSpace(self[self.position])
    {
      unsafe self.position += 1
    }
  }

  /// Skips to just after the next `terminator`.
  @usableFromInline
  mutating func skip(past terminator: StaticString) throws(XMLSyntaxError) {
    let first = unsafe terminator.utf8Start[0]
    let length = terminator.utf8CodeUnitCount
    var offset = unsafe self.position
    while true {
      offset = unsafe self.find(first, from: offset)
      guard unsafe offset + length <= self.count else {
        throw unsafe self.error("missing \(terminator)")
      }
      if unsafe memcmp(self.base + offset, terminator.utf8Start, length) == 0 {
        unsafe self.position = offset + length
        return
      }
      offset += 1
    }
  }

  @inline(__always) @usableFromInline
  func hasPrefix(_ prefix: StaticString, at offset: Int) -> Bool {
    let length = prefix.utf8CodeUnitCount
    return unsafe offset + length <= self.count
      && memcmp(self.base + offset, prefix.utf8Start, length) == 0
  }

  /// Skips the rest of a comment.
  ///
  /// A comment cannot contain `--`.
  @usableFromInline
  mutating func skipComment() throws(XMLSyntaxError) {
    try unsafe self.skip(past: "--")
    guard unsafe self.position < self.count,
      unsafe self[self.position] == UInt8(ascii: ">")
    else { throw unsafe self.error("'--' in a comment") }
    unsafe self.position += 1
  }

  /// Skips a comment, CDATA section, or declaration. `position` is just
  /// after `<!`.
  @usableFromInline
  mutating func skipMarkup() throws(XMLSyntaxError) {
    if unsafe self.hasPrefix("--", at: self.position) {
      unsafe self.position += 2
      try unsafe self.skipComment()
    } else if unsafe self.hasPrefix("[CDATA[", at: self.position) {
      unsafe self.position += 7
      try unsafe self.skip(past: "]]>")
    } else {
      // A declaration such as <!DOCTYPE ...>, which can hold an internal
      // subset in brackets.
      var brackets = 0
      while unsafe self.position < self.count {
        let byte = unsafe self[self.position]
        unsafe self.position += 1
        switch byte {
        case UInt8(ascii: "["): brackets += 1
        case UInt8(ascii: "]"): brackets -= 1
        case UInt8(ascii: ">") where brackets == 0: return
        case UInt8(ascii: "\""), UInt8(ascii: "'"):
          unsafe self.position = self.find(byte, from: self.position) + 1
        default: break
        }
      }
      throw unsafe self.error("unterminated declaration")
    }
  }

  // MARK: - Tags

  /// Reads the prolog and the start tag of the root element.
  @usableFromInline
  mutating func readRoot() throws(XMLSyntaxError) {
    if unsafe self.hasPrefix("\u{FEFF}", at: 0) { unsafe self.position = 3 }
    while true {
      unsafe self.skipSpace()
      guard unsafe self.position < self.count,
        unsafe self[self.position] == UInt8(ascii: "<")
      else { throw unsafe self.error("missing root element") }
      unsafe self.position += 1
      guard unsafe self.position < self.count else {
        throw unsafe self.error("missing root element")
      }
      switch unsafe self[self.position] {
      case UInt8(ascii: "?"):
        try unsafe self.skip(past: "?>")
      case UInt8(ascii: "!"):
        unsafe self.position += 1
        try unsafe self.skipMarkup()
      default:
        try unsafe self.readStartTag()
        return
      }
    }
  }

  /// Checks that only comments, processing instructions, and white space
  /// follow the root element.
  @usableFromInline
  mutating func readEpilog() throws(XMLSyntaxError) {
    while true {
      unsafe self.skipSpace()
      guard unsafe self.position < self.count else { return }
      guard
        unsafe self.hasPrefix("<?", at: self.position)
          || self.hasPrefix("<!--", at: self.position)
      else { throw unsafe self.error("content after the root element") }
      unsafe self.position += 2
      if unsafe self[self.position - 1] == UInt8(ascii: "?") {
        try unsafe self.skip(past: "?>")
      } else {
        unsafe self.position += 2
        try unsafe self.skipComment()
      }
    }
  }

  /// Reads a start tag. `position` is just after `<`.
  @usableFromInline
  mutating func readStartTag() throws(XMLSyntaxError) {
    let nameStart = unsafe self.position
    unsafe self.position = self.findNameEnd(from: nameStart)
    let nameCount = unsafe self.position - nameStart
    guard nameCount > 0, unsafe Self.isNameStart(self[nameStart]) else {
      throw unsafe self.error("invalid element name")
    }
    unsafe self.stack.append((nameStart, nameCount))
    unsafe self.attributes.count = 0

    while true {
      unsafe self.skipSpace()
      guard unsafe self.position < self.count else {
        throw unsafe self.error("unterminated start tag")
      }
      switch unsafe self[self.position] {
      case UInt8(ascii: ">"):
        unsafe self.position += 1
        unsafe self.emptyElement = false
        return
      case UInt8(ascii: "/"):
        guard unsafe self.position + 1 < self.count,
          unsafe self[self.position + 1] == UInt8(ascii: ">")
        else { throw unsafe self.error("expected '>'") }
        unsafe self.position += 2
        unsafe self.emptyElement = true
        return
      default:
        try unsafe self.readAttribute()
      }
    }
  }

  @usableFromInline
  mutating func readAttribute() throws(XMLSyntaxError) {
    let nameStart = unsafe self.position
    while unsafe self.position < self.count,
      unsafe !Self.isNameEnd(self[self.position])
    {
      unsafe self.position += 1
    }
    let nameCount = unsafe self.position - nameStart
    guard nameCount > 0, unsafe Self.isNameStart(self[nameStart]) else {
      throw unsafe self.error("invalid attribute name")
    }
    unsafe self.skipSpace()
    guard unsafe self.position < self.count,
      unsafe self[self.position] == UInt8(ascii: "=")
    else { throw unsafe self.error("expected '='") }
    unsafe self.position += 1
    unsafe self.skipSpace()
    guard unsafe self.position < self.count else {
      throw unsafe self.error("expected quote")
    }
    let quote = unsafe self[self.position]
    guard quote == UInt8(ascii: "\"") || quote == UInt8(ascii: "'") else {
      throw unsafe self.error("expected quote")
    }
    let valueStart = unsafe self.position + 1
    let valueEnd = unsafe self.find(quote, from: valueStart)
    guard unsafe valueEnd < self.count else {
      throw unsafe self.error("unterminated attribute value")
    }
    if unsafe self.find(UInt8(ascii: "<"), from: valueStart) < valueEnd {
      throw unsafe self.error("'<' in an attribute value")
    }
    for index in unsafe 0..<self.attributes.count {
      let other = unsafe self.attributes[index]
      if other.nameCount == nameCount,
        unsafe memcmp(
          self.base + other.nameStart, self.base + nameStart, nameCount)
          == 0
      {
        throw unsafe self.error("duplicate attribute")
      }
    }
    unsafe self.position = valueEnd + 1
    unsafe self.attributes.append(
      XMLAttributeRange(
        nameStart: nameStart, nameCount: nameCount,
        valueStart: valueStart, valueCount: valueEnd - valueStart))
  }

  /// Reads an end tag and closes the open element. `position` is just after
  /// `</`.
  @usableFromInline
  mutating func readEndTag() throws(XMLSyntaxError) {
    guard unsafe self.stack.count > 0 else {
      throw unsafe self.error("unexpected end tag")
    }
    unsafe self.stack.count -= 1
    let open = unsafe self.stack[self.stack.count]
    guard unsafe open.start + open.count <= self.count,
      unsafe self.position + open.count <= self.count,
      unsafe memcmp(
        self.base + self.position, self.base + open.start, open.count)
        == 0
    else { throw unsafe self.error("mismatched end tag") }
    unsafe self.position += open.count
    unsafe self.skipSpace()
    guard unsafe self.position < self.count,
      unsafe self[self.position] == UInt8(ascii: ">")
    else { throw unsafe self.error("mismatched end tag") }
    unsafe self.position += 1
  }

  // MARK: - Content

  /// Moves to the next child element of the open element.
  ///
  /// Returns `true` after it reads the start tag of a child, which is then
  /// the open element. Returns `false` after it reads the end tag of the open
  /// element. The reader skips text, comments, and processing instructions.
  @usableFromInline
  mutating func nextChild() throws(XMLSyntaxError) -> Bool {
    if unsafe self.emptyElement {
      unsafe self.emptyElement = false
      unsafe self.stack.count -= 1
      return false
    }
    while true {
      let open = unsafe self.find(UInt8(ascii: "<"), from: self.position)
      guard unsafe open + 1 < self.count else {
        unsafe self.position = open
        throw unsafe self.error("unclosed element")
      }
      unsafe self.position = open + 2
      switch unsafe self[open + 1] {
      case UInt8(ascii: "/"):
        try unsafe self.readEndTag()
        return false
      case UInt8(ascii: "!"):
        try unsafe self.skipMarkup()
      case UInt8(ascii: "?"):
        try unsafe self.skip(past: "?>")
      default:
        unsafe self.position = open + 1
        try unsafe self.readStartTag()
        return true
      }
    }
  }

  /// Skips the rest of the open elements until `depth` elements are open.
  @usableFromInline
  mutating func skip(toDepth depth: Int) throws(XMLSyntaxError) {
    while unsafe self.stack.count > depth {
      _ = try unsafe self.nextChild()
    }
  }

  /// Reads the text of the open element and closes it.
  ///
  /// The text is the content of the element without its child elements. If
  /// the text is only white space, the result is empty. The result is valid
  /// until the next call to the reader.
  @usableFromInline
  mutating func readText() throws(XMLSyntaxError) -> UnsafeBufferPointer<UInt8>
  {
    if unsafe self.emptyElement {
      unsafe self.emptyElement = false
      unsafe self.stack.count -= 1
      return unsafe UnsafeBufferPointer(start: self.base, count: 0)
    }
    // Fast path: one run of plain text, then the end tag.
    let textStart = unsafe self.position
    let offset = unsafe self.findMarkup(from: textStart)
    guard unsafe offset + 1 < self.count,
      unsafe self[offset] == UInt8(ascii: "<"),
      unsafe self[offset + 1] == UInt8(ascii: "/")
    else { return try unsafe self.readTextSlow() }
    unsafe self.position = offset + 2
    try unsafe self.readEndTag()
    var space = true
    for index in textStart..<offset where unsafe !Self.isSpace(self[index]) {
      space = false
      break
    }
    if space { return unsafe UnsafeBufferPointer(start: self.base, count: 0) }
    return unsafe UnsafeBufferPointer(
      start: self.base + textStart, count: offset - textStart)
  }

  /// Returns the offset of the next `<`, `&`, or carriage return at or after
  /// `from`, or `count`.
  @inline(__always) @usableFromInline
  func findMarkup(from: Int) -> Int {
    // Test eight bytes at a time for a byte that is equal to one of the
    // three bytes. A zero byte in `word ^ pattern` marks a match.
    let ones: UInt64 = 0x0101_0101_0101_0101
    let highs: UInt64 = 0x8080_8080_8080_8080
    var offset = from
    while unsafe offset + 8 <= self.count {
      let word = unsafe UnsafeRawPointer(self.base + offset).loadUnaligned(
        as: UInt64.self)
      let lt = word ^ (ones &* UInt64(UInt8(ascii: "<")))
      let amp = word ^ (ones &* UInt64(UInt8(ascii: "&")))
      let cr = word ^ (ones &* 0x0D)
      let zero =
        ((lt &- ones) & ~lt) | ((amp &- ones) & ~amp) | ((cr &- ones) & ~cr)
      let found = zero & highs
      if found != 0 {
        return offset + found.trailingZeroBitCount / 8
      }
      offset += 8
    }
    while unsafe offset < self.count {
      let byte = unsafe self[offset]
      if byte == UInt8(ascii: "<") || byte == UInt8(ascii: "&") || byte == 0x0D
      {
        return offset
      }
      offset += 1
    }
    return offset
  }

  /// Reads text with references, line ends, CDATA, comments, and child
  /// elements.
  @usableFromInline
  mutating func readTextSlow() throws(XMLSyntaxError) -> UnsafeBufferPointer<
    UInt8
  > {
    let depth = unsafe self.stack.count
    unsafe self.scratch.count = 0
    var space = true
    while true {
      let runStart = unsafe self.position
      let runEnd = unsafe self.find(UInt8(ascii: "<"), from: runStart)
      guard unsafe runEnd + 1 < self.count else {
        unsafe self.position = runEnd
        throw unsafe self.error("unclosed element")
      }
      try unsafe self.appendText(from: runStart, to: runEnd, space: &space)
      unsafe self.position = runEnd + 2
      switch unsafe self[runEnd + 1] {
      case UInt8(ascii: "/"):
        try unsafe self.readEndTag()
        if space { unsafe self.scratch.count = 0 }
        return unsafe self.scratch.buffer
      case UInt8(ascii: "!"):
        if unsafe self.hasPrefix("[CDATA[", at: self.position) {
          let start = unsafe self.position + 7
          unsafe self.position = start
          try unsafe self.skip(past: "]]>")
          let end = unsafe self.position - 3
          for offset in start..<end where unsafe !Self.isSpace(self[offset]) {
            space = false
            break
          }
          unsafe self.scratch.append(self.base + start, count: end - start)
        } else {
          try unsafe self.skipMarkup()
        }
      case UInt8(ascii: "?"):
        try unsafe self.skip(past: "?>")
      default:
        // White space before a child element is part of the text only if
        // the text before it is not only white space.
        if space { unsafe self.scratch.count = 0 }
        unsafe self.position = runEnd + 1
        try unsafe self.readStartTag()
        try unsafe self.skip(toDepth: depth)
      }
    }
  }

  /// Appends text to `scratch`.
  ///
  /// It replaces character references and normalizes line ends. In an
  /// attribute value, each white space character becomes a space.
  @usableFromInline
  mutating func appendText(
    from start: Int, to end: Int, space: inout Bool, attribute: Bool = false
  ) throws(XMLSyntaxError) {
    var offset = start
    while offset < end {
      let byte = unsafe self[offset]
      switch byte {
      case UInt8(ascii: "&"):
        let semicolon = unsafe self.find(UInt8(ascii: ";"), from: offset + 1)
        guard semicolon < end else {
          unsafe self.position = offset
          throw unsafe self.error("unterminated reference")
        }
        guard
          let scalar = unsafe self.reference(from: offset + 1, to: semicolon)
        else {
          unsafe self.position = offset
          throw unsafe self.error("unknown reference")
        }
        if space,
          unsafe !(scalar.value < 0x80 && Self.isSpace(UInt8(scalar.value)))
        {
          space = false
        }
        var utf8 = String(scalar)
        utf8.withUTF8 {
          unsafe self.scratch.append(
            $0.baseAddress.unsafelyUnwrapped, count: $0.count)
        }
        offset = semicolon + 1
      case 0x0D:
        unsafe self.scratch.append(attribute ? 0x20 : 0x0A)
        offset += 1
        if offset < end, unsafe self[offset] == 0x0A { offset += 1 }
      case 0x09 where attribute, 0x0A where attribute:
        unsafe self.scratch.append(0x20)
        offset += 1
      default:
        if space, unsafe !Self.isSpace(byte) { space = false }
        unsafe self.scratch.append(byte)
        offset += 1
      }
    }
  }

  /// Returns the character for the reference between `&` and `;`.
  @usableFromInline
  func reference(from start: Int, to end: Int) -> Unicode.Scalar? {
    let name = unsafe UnsafeBufferPointer(
      start: self.base + start, count: end - start)
    if unsafe name.first == UInt8(ascii: "#") {
      var value: UInt32 = 0
      var radix: UInt32 = 10
      var digits = unsafe name.dropFirst()
      if unsafe digits.first == UInt8(ascii: "x") {
        radix = 16
        unsafe digits = digits.dropFirst()
      }
      guard unsafe !digits.isEmpty else { return nil }
      for unsafe byte in unsafe digits {
        let digit: UInt32
        switch byte {
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
          digit = UInt32(byte - UInt8(ascii: "0"))
        case UInt8(ascii: "a")...UInt8(ascii: "f") where radix == 16:
          digit = UInt32(byte - UInt8(ascii: "a") + 10)
        case UInt8(ascii: "A")...UInt8(ascii: "F") where radix == 16:
          digit = UInt32(byte - UInt8(ascii: "A") + 10)
        default: return nil
        }
        value = value &* radix &+ digit
        guard value <= 0x10FFFF else { return nil }
      }
      switch value {
      case 0x9, 0xA, 0xD, 0x20...0xD7FF, 0xE000...0xFFFD, 0x10000...0x10FFFF:
        return Unicode.Scalar(value)
      default:
        return nil
      }
    }
    switch unsafe String(decoding: name, as: UTF8.self) {
    case "lt": return "<"
    case "gt": return ">"
    case "amp": return "&"
    case "apos": return "'"
    case "quot": return "\""
    default: return nil
    }
  }

  /// Returns the value of an attribute of the last start tag.
  ///
  /// The result is valid until the next call to the reader.
  @usableFromInline
  mutating func attributeValue(
    start: Int, count: Int
  ) throws(XMLSyntaxError) -> UnsafeBufferPointer<UInt8> {
    let end = start + count
    var plain = true
    for offset in start..<end {
      switch unsafe self[offset] {
      case UInt8(ascii: "&"), 0x09, 0x0A, 0x0D: plain = false
      default: break
      }
    }
    if plain {
      return unsafe UnsafeBufferPointer(start: self.base + start, count: count)
    }
    unsafe self.scratch.count = 0
    var space = true
    try unsafe self.appendText(
      from: start, to: end, space: &space, attribute: true)
    return unsafe self.scratch.buffer
  }
}
