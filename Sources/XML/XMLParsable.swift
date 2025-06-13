//
//  File.swift
//  swift-mmio
//
//  Created by Rauhul Varma on 6/12/25.
//

import Foundation

public enum XMLParseError: Error {
  case buildIncomplete
}

public protocol _XMLParsable {
  static func _buildMask() -> UInt64
  // FIXME: _buildPartial -> initPartial + add deinitPartial
  static func _buildPartial() -> UnsafeMutableRawPointer
  static func _buildChild(name: UnsafePointer<CChar>) -> (any _XMLParsable.Type)?
  static func _buildAny(partial: UnsafeMutableRawPointer, name: UnsafePointer<CChar>, value: Any)
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
