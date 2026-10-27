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

public import MMIOUtilities

/// A type that decodes from the text of an element or of an attribute value.
public protocol XMLValueDecodable {
  init(_ text: XMLText) throws

  /// Decodes text and stores the result in a destination.
  ///
  /// Do not implement this requirement. The decoder calls it through the
  /// metatype of the value, so that it can decode each type without knowing
  /// the type.
  static func _decode(_ text: XMLText, into destination: XMLDestination)
}

extension XMLValueDecodable {
  @inlinable
  public static func _decode(
    _ text: XMLText,
    into destination: XMLDestination
  ) {
    destination.store(Result { try Self(text) })
  }
}

/// A type that decodes from the attributes and children of an element.
///
/// Use the `@XMLElement` macro to generate the conformance for a struct.
public protocol XMLElementDecodable {
  associatedtype XMLBuilder: XMLElementBuilder where XMLBuilder.Value == Self
}

/// A type that collects the attributes and children of an element while
/// expat parses the element, and then builds a value.
///
/// A builder stores each member in a slot. A slot keeps the result of the
/// decoding, so that ``build()`` can throw the first error in member order.
public protocol XMLElementBuilder {
  associatedtype Value

  init()

  /// Receives an attribute of the element.
  mutating func attribute(_ name: XMLName, _ value: XMLText)

  /// Returns the frame that decodes a child element, or nil to skip the
  /// child element.
  static func child(
    _ name: XMLName,
    of builder: XMLBuilderPointer<Self>
  ) -> XMLFrame?

  /// Builds the value, and takes the values out of the slots.
  mutating func build() throws(XMLBuildError) -> Value

  /// Handles an event for an element that the builder decodes.
  ///
  /// Do not implement this requirement. The decoder calls it through the
  /// metatype of the builder, so that it can decode each type without
  /// knowing the type.
  static func _handle(
    _ event: XMLFrameEvent,
    builder: UnsafeMutableRawPointer,
    destination: XMLDestination
  ) -> XMLFrame?
}

/// An event for an open element that a builder decodes.
public enum XMLFrameEvent {
  /// The element has an attribute.
  case attribute(XMLName, XMLText)
  /// A child element starts. The builder returns the frame for the child
  /// element, or nil to skip the child element.
  case child(XMLName)
  /// The element ends. The builder builds the value, stores the value in the
  /// destination, and frees itself.
  case end
  /// The decoding stops because of an error. The builder frees itself.
  case cancel
}

extension XMLElementBuilder {
  @inlinable
  public static func _handle(
    _ event: XMLFrameEvent,
    builder: UnsafeMutableRawPointer,
    destination: XMLDestination
  ) -> XMLFrame? {
    let builder = builder.assumingMemoryBound(to: Self.self)
    switch event {
    case .attribute(let name, let value):
      builder.pointee.attribute(name, value)
      return nil
    case .child(let name):
      return Self.child(name, of: XMLBuilderPointer(builder))
    case .end:
      let result: Result<Value, any Error>
      do throws(XMLBuildError) {
        result = .success(try builder.pointee.build())
      } catch {
        result = .failure(error.error)
      }
      builder.deinitialize(count: 1)
      builder.deallocate()
      destination.store(result)
      return nil
    case .cancel:
      builder.deinitialize(count: 1)
      builder.deallocate()
      return nil
    }
  }

  /// Builds the value of an optional inline member.
  ///
  /// If the element does not have a value that the member needs, the result
  /// is nil.
  @inlinable
  public mutating func buildOptional() throws(XMLBuildError) -> Value? {
    do {
      return try self.build()
    } catch .missingValue {
      return nil
    } catch {
      throw error
    }
  }

  /// Builds the value of an inline member.
  @inlinable
  public mutating func buildRequired() throws(XMLBuildError) -> Value {
    let value = try self.buildOptional()
    do {
      return try value.unwrap()
    } catch {
      throw .failure(error)
    }
  }
}

/// An error that stops a builder from building its value.
///
/// The builders use typed throws, so that a missing value does not allocate
/// an error. Optional members and choices handle missing values often.
public enum XMLBuildError: Error {
  /// The element does not have a value that a member needs.
  case missingValue(name: String)
  /// A member failed to decode.
  case failure(any Error)

  /// The error to report to the caller of the decoder.
  @inlinable
  public var error: any Error {
    switch self {
    case .missingValue(let name): XMLError.missingValue(name: name)
    case .failure(let error): error
    }
  }
}

/// A member that decodes from the first child element or attribute that has
/// the name of the member.
public struct XMLSlot<Value> {
  @usableFromInline
  var result: Result<Value, any Error>?

  @inlinable
  public init() {
    self.result = nil
  }

  @inlinable
  public var isEmpty: Bool { self.result == nil }

  /// Takes the value, or throws an error if the slot is empty.
  @inlinable
  public mutating func required(
    _ name: String
  ) throws(XMLBuildError) -> Value {
    guard let value = try self.optional() else {
      throw .missingValue(name: name)
    }
    return value
  }

  /// Takes the value, or returns nil if the slot is empty.
  @inlinable
  public mutating func optional() throws(XMLBuildError) -> Value? {
    switch self.result.take() {
    case .success(let value): value
    case .failure(let error): throw .failure(error)
    case nil: nil
    }
  }
}

extension XMLSlot where Value: XMLValueDecodable {
  /// Decodes an attribute value, if the slot is empty.
  @inlinable
  public mutating func decode(_ text: XMLText) {
    guard self.isEmpty else { return }
    self.result = Result { try Value(text) }
  }
}

/// A member that decodes from all child elements that have the name of the
/// member.
public struct XMLArraySlot<Element> {
  @usableFromInline
  var elements: [Element]
  @usableFromInline
  var error: (any Error)?

  @inlinable
  public init() {
    self.elements = []
    self.error = nil
  }

  /// Appends an element, unless an earlier element failed to decode.
  @inlinable
  mutating func store(_ result: consuming Result<Element, any Error>) {
    guard self.error == nil else { return }
    switch consume result {
    case .success(let element): self.elements.append(element)
    case .failure(let error): self.error = error
    }
  }

  /// Takes the elements, or throws the error of the first element that
  /// failed to decode.
  @inlinable
  public mutating func get() throws(XMLBuildError) -> [Element] {
    if let error = self.error { throw .failure(error) }
    var elements: [Element] = []
    swap(&elements, &self.elements)
    return elements
  }
}

/// A pointer to the slot or array slot that receives the decoded value of an
/// element.
public struct XMLDestination {
  @usableFromInline
  var pointer: UnsafeMutableRawPointer
  @usableFromInline
  var isArray: Bool

  @inlinable
  init<Value>(_ slot: UnsafeMutablePointer<XMLSlot<Value>>) {
    self.pointer = UnsafeMutableRawPointer(slot)
    self.isArray = false
  }

  @inlinable
  init<Element>(_ slot: UnsafeMutablePointer<XMLArraySlot<Element>>) {
    self.pointer = UnsafeMutableRawPointer(slot)
    self.isArray = true
  }

  @inlinable
  func store<Value>(_ result: consuming Result<Value, any Error>) {
    if self.isArray {
      self.pointer.assumingMemoryBound(to: XMLArraySlot<Value>.self).pointee
        .store(result)
    } else {
      self.pointer.assumingMemoryBound(to: XMLSlot<Value>.self).pointee
        .result = result
    }
  }
}

/// A pointer to a builder in an open frame.
///
/// The builder of a frame does not move while the frame is open, so the
/// pointers to its slots stay valid until the frame ends.
public struct XMLBuilderPointer<Builder> {
  @usableFromInline
  let pointer: UnsafeMutablePointer<Builder>

  @inlinable
  init(_ pointer: UnsafeMutablePointer<Builder>) {
    self.pointer = pointer
  }

  /// Returns a pointer to a member of the builder, such as the builder of an
  /// inline member.
  @inlinable
  public func member<Member>(
    _ keyPath: WritableKeyPath<Builder, Member>
  ) -> XMLBuilderPointer<Member> {
    XMLBuilderPointer<Member>(self.pointer(to: keyPath))
  }

  @inlinable
  func pointer<Member>(
    to keyPath: WritableKeyPath<Builder, Member>
  ) -> UnsafeMutablePointer<Member> {
    guard let member = self.pointer.pointer(to: keyPath) else {
      preconditionFailure("A builder member must be a stored property")
    }
    return member
  }

  /// Returns the frame that decodes a child element into a slot, or nil if
  /// an earlier child element filled the slot.
  @inlinable
  public func decode<Value>(
    _ keyPath: WritableKeyPath<Builder, XMLSlot<Value>>
  ) -> XMLFrame? where Value: XMLValueDecodable {
    let slot = self.pointer(to: keyPath)
    guard slot.pointee.isEmpty else { return nil }
    return XMLFrame(.value(Value.self), into: XMLDestination(slot))
  }

  /// Returns the frame that decodes a child element into a slot, or nil if
  /// an earlier child element filled the slot.
  @inlinable
  public func decode<Value>(
    _ keyPath: WritableKeyPath<Builder, XMLSlot<Value>>
  ) -> XMLFrame? where Value: XMLElementDecodable {
    let slot = self.pointer(to: keyPath)
    guard slot.pointee.isEmpty else { return nil }
    return XMLFrame(element: Value.self, into: XMLDestination(slot))
  }

  /// Returns the frame that decodes a child element into an array slot.
  @inlinable
  public func decode<Element>(
    _ keyPath: WritableKeyPath<Builder, XMLArraySlot<Element>>
  ) -> XMLFrame? where Element: XMLValueDecodable {
    let slot = self.pointer(to: keyPath)
    return XMLFrame(.value(Element.self), into: XMLDestination(slot))
  }

  /// Returns the frame that decodes a child element into an array slot.
  @inlinable
  public func decode<Element>(
    _ keyPath: WritableKeyPath<Builder, XMLArraySlot<Element>>
  ) -> XMLFrame? where Element: XMLElementDecodable {
    let slot = self.pointer(to: keyPath)
    return XMLFrame(element: Element.self, into: XMLDestination(slot))
  }
}

/// The decoding of an open element.
public struct XMLFrame {
  @usableFromInline
  enum Decoder {
    /// The element decodes from its text.
    case value(any XMLValueDecodable.Type)
    /// The element decodes with a builder.
    case element(any XMLElementBuilder.Type, UnsafeMutableRawPointer)
  }

  @usableFromInline
  var decoder: Decoder
  @usableFromInline
  var destination: XMLDestination

  @inlinable
  init(_ decoder: Decoder, into destination: XMLDestination) {
    self.decoder = decoder
    self.destination = destination
  }

  /// Makes a frame with a new builder for a type.
  @inlinable
  init<Value>(element _: Value.Type, into destination: XMLDestination)
  where Value: XMLElementDecodable {
    let builder = UnsafeMutablePointer<Value.XMLBuilder>.allocate(capacity: 1)
    builder.initialize(to: Value.XMLBuilder())
    let decoder = Decoder.element(
      Value.XMLBuilder.self, UnsafeMutableRawPointer(builder))
    self.init(decoder, into: destination)
  }
}
