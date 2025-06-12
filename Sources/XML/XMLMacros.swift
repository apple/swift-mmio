//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@attached(peer)
public macro XMLAttribute() =
  #externalMacro(module: "XMLMacros", type: "XMLMarkerMacro")

@attached(
  extension, names: named(init(_:)), conformances: XMLElementInitializable)
public macro XMLElement() =
  #externalMacro(module: "XMLMacros", type: "XMLElementMacro")

@attached(peer)
public macro XMLInlineElement() =
  #externalMacro(module: "XMLMacros", type: "XMLMarkerMacro")
