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

enum Errors: Error, @unchecked Sendable {
  case missingValue(name: String)
  case unknownValue(String)
  case unknownElement(XMLElement)
}

// XMLElement.child(element) -> T
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLElementInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: Errors.missingValue(name: name))
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
      .unwrap(or: Errors.missingValue(name: name))
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

// XMLElement.child(node) -> T
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromChild name: String
  ) throws -> T where T: XMLNodeInitializable {
    try self
      .decode(T?.self, fromChild: name)
      .unwrap(or: Errors.missingValue(name: name))
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

// XMLElement.attribute(node) -> T
extension XMLElement {
  func decode<T>(
    _: T.Type = T.self,
    fromAttribute name: String
  ) throws -> T where T: XMLNodeInitializable {
    try self
      .decode(T?.self, fromAttribute: name)
      .unwrap(or: Errors.missingValue(name: name))
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
