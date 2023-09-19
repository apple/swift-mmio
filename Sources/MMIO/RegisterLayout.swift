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

public protocol RegisterLayout {
  associatedtype Raw: RegisterLayoutRaw where Raw.Layout == Self
  associatedtype Read: RegisterLayoutRead
  where Read.Layout == Self, Read.MMIOVolatileRepresentation == Raw.MMIOVolatileRepresentation
  associatedtype Write: RegisterLayoutWrite
  where Write.Layout == Self, Write.MMIOVolatileRepresentation == Raw.MMIOVolatileRepresentation
}

public protocol RegisterLayoutRaw: MMIOVolatileValue {
  associatedtype Layout: RegisterLayout where Layout.Raw == Self
  var _rawStorage: Self.MMIOVolatileRepresentation { get set }
  init(_ value: Layout.Read)
  init(_ value: Layout.Write)
}

public protocol RegisterLayoutRead: MMIOVolatileValue {
  associatedtype Layout: RegisterLayout where Layout.Read == Self
  var _rawStorage: Self.MMIOVolatileRepresentation { get set }
  init(_ value: Layout.Raw)
}

extension RegisterLayoutRead {
  public var raw: Layout.Raw {
    _read {
      yield Layout.Raw(self)
    }
    _modify {
      var raw = Layout.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}

public protocol RegisterLayoutWrite: MMIOVolatileValue {
  associatedtype Layout: RegisterLayout where Layout.Write == Self
  var _rawStorage: Self.MMIOVolatileRepresentation { get set }
  init(_ value: Layout.Raw)
  init(_ read: Layout.Read)
}

extension RegisterLayoutWrite {
  public var raw: Layout.Raw {
    _read {
      yield Layout.Raw(self)
    }
    _modify {
      var raw = Layout.Raw(self)
      yield &raw
      self = Self(raw)
    }
  }
}
