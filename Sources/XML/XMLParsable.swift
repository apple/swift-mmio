//
//  File.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 6/12/25.
//

import Foundation

public protocol _XMLParsable {
  static func _buildMask() -> UInt64
  // FIXME: _buildPartial -> initPartial + add deinitPartial
  static func _buildPartial() -> UnsafeMutableRawPointer
  static func _buildChild(name: UnsafePointer<CChar>) -> (any _XMLParsable.Type)?
  static func _buildAny(partial: UnsafeMutableRawPointer, name: String, value: Any) throws
  static func _buildComplete(partial: UnsafeMutableRawPointer) throws -> Self
}

public struct _XMLPartial<Value: _XMLParsable> {
  // FIXME: add isa in debug builds
  public var initialized: UInt64
  public var value: Value
}

//extension Optional where Wrapped: _XMLParsable {
//
//}


//extension _XMLParsable {
//  static func buildComplete(pointer: UnsafeMutableRawPointer) throws -> Self {
//    let partial = pointer.bindMemory(to: _XMLPartial<Self>.self, capacity: 1)
//    defer { partial.deallocate() }
//
//    let initialized = partial.pointer(to: \.initialized)!.pointee
//    let value       = partial.pointer(to: \.value)!
//
//    if (initialized & Self._buildMask()) == 0 {
//      return value.move()
//    } else {
//      fatalError()
//      // deinit all props in `initialized` where value == 1
//      // incomplete initialization error
//    }
//  }
//}

//protocol XMLParsable {
//  static func makeBuilder() -> UnsafeRawPointer {
//
//  }
//
//  static func builder(for name: String) -> UnsafeRawPointer {
//    switch name.utf8 {
//    case "name".utf8:
//      return SVDCPU.makeBuilder()
//    default: fatalError()
//    }
//  }
//
//  static func buildAny(pointer: UnsafeMutableRawPointer, name: String, value: Any) throws {
//    switch (name.utf8, value) {
//    case ("sauRegionsConfig".utf8, let value as SVDSAURegions?):
//      build_sauRegionsConfig(pointer: pointer)
//    default: fatalError()
//    }
//  }
//
//  static func buildName(pointer: UnsafeMutableRawPointer, value: SVDCPUName) throws {
//    let selfPointer = pointer.bindMemory(to: Self.self, capacity: 1)
//    let namePointer = selfPointer.pointer(to: \.name)
//    // if bitSet has name { error }
//    namePointer!.initialize(to: value)
//    // bit set add name
//  }
//}
