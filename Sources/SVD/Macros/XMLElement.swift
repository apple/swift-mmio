//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import MMIOUtilities

#if canImport(FoundationXML)
import FoundationXML
#endif

// Support for @XMLElement properties
// where: @XMLInlineElement & XMLElementInitializable
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self)
      .unwrap()
  }

  func decode<T>(
    _: T?.Type = T?.self
  ) throws -> T? where T: XMLElementInitializable {
    do {
      return try T.init(self)
    } catch XMLError.missingValue {
      return nil
    }
  }
}

// Support for @XMLElement properties
// where: implied @XMLChild & XMLElementInitializable
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: T?.Type = T?.self,
    fromChild name: String
  ) throws -> T? where T: XMLElementInitializable {
    try (self.children ?? [])
      .first { $0.name == name }
      .flatMap { $0 as? XMLElement }
      .map(T.init)
  }

  func decode<T>(
    _: [T].Type = [T].self,
    fromChild name: String
  ) throws -> [T] where T: XMLElementInitializable {
    try self
      .decode([T]?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: [T]?.Type = [T]?.self,
    fromChild name: String
  ) throws -> [T]? where T: XMLElementInitializable {
    try (self.children ?? [])
      .lazy
      .filter { $0.name == name }
      .compactMap { $0 as? XMLElement }
      .map(T.init)
  }
}

// Support for @XMLElement properties
// where: implied @XMLChild & XMLNodeInitializable
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLNodeInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: T?.Type = T?.self,
    fromChild name: String
  ) throws -> T? where T: XMLNodeInitializable {
    try self
      .children?
      .first { $0.name == name }
      .map(T.init)
  }
}

// Support for @XMLElement properties
// where: @XMLAttribute & XMLNodeInitializable
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromAttribute name: String
  ) throws -> T where T: XMLNodeInitializable {
    try self
      .decode(T?.self, fromAttribute: name)
      .unwrap(or: XMLError.missingValue(name: name))
  }

  func decode<T>(
    _: T?.Type = T?.self,
    fromAttribute name: String
  ) throws -> T? where T: XMLNodeInitializable {
    try self
      .attribute(forName: name)
      .map(T.init)
  }
}
