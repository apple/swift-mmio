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

import XCTest
@testable import MMIO


fileprivate enum UMSEL0Values: UInt8, BitFieldProjectable, CaseIterable {
    case asynchronous_usart = 0x0
    case synchronous_usart = 0x1
    case master_spi = 0x3
    case invalidValue = 0x4
    
    public static var bitWidth: Int { 2 }
}

fileprivate enum TestEnum16Bit: UInt16, BitFieldProjectable {
    case value0 = 0x0000
    case value1 = 0x0001
    case value2 = 0x0002
    case value3 = 0x0004
    case maxValue = 0xFFFF
    
    public static var bitWidth: Int { 16 }
}

class RawRepresentableExtensionTests: XCTestCase {
    
    /// Tests if the initializer properly creates an enum instance from a storage value for UMSEL0Values.
    func testInitializationUMSEL0Values() {
        let valueFromStorage: UMSEL0Values = UMSEL0Values(storage: UInt8(0x1))
        XCTAssertEqual(valueFromStorage, .synchronous_usart, "Initialization from storage did not yield expected value for UMSEL0Values.")
    }
    
    /// Verifies that the storage function correctly returns the raw value associated with an enum case for UMSEL0Values.
    func testStorageFunctionUMSEL0Values() {
        // Test storage function of the UMSEL0Values
        let value: UMSEL0Values = .master_spi
        let storageValue: UInt8 = value.storage(UInt8.self)
        XCTAssertEqual(storageValue, 0x3, "Storage function did not return the expected raw value for UMSEL0Values.")
    }
    
    /// Confirms that converting an enum to a storage value and back to an enum results in the original enum value for UMSEL0Values. This validates the integrity of both the initializer and the storage function.
    func testRoundTripConversionUMSEL0Values() {
        let originalValue: UMSEL0Values = .master_spi
        let storageValue: UInt8 = originalValue.storage(UInt8.self)
        let convertedValue = UMSEL0Values(storage: storageValue)
        XCTAssertEqual(originalValue, convertedValue, "Round-trip conversion failed for UMSEL0Values.")
    }
    
    
    // This test is only included to highlight the fact that Swift is not enforcing bit width constraint at the enum level. This means a user could define an enum case that doesn't adhere to the bitWidth constraint without encountering a compile-time error.
    func testInitializationFomInvalidValue() {
        let valueFromStorage: UMSEL0Values = UMSEL0Values(storage: UInt8(0x4))
        XCTAssertEqual(valueFromStorage, .invalidValue, "Initialization from storage did not yield expected value for UMSEL0Values.")
    }
    
    /// Tests if the initializer correctly creates a 16-bit enum instance from a storage value for TestEnum16Bit.
    func testInitialization16Bit() {
        let valueFromStorage: TestEnum16Bit = TestEnum16Bit(storage: UInt16(0x0002))
        XCTAssertEqual(valueFromStorage, .value2, "Initialization from storage did not yield expected value for 16-bit enum.")
    }
    
    /// Verifies that the storage function correctly returns the raw value associated with a 16-bit enum case for TestEnum16Bit.
    func testStorageFunction16Bit() {
        let value: TestEnum16Bit = .value3
        let storageValue: UInt16 = value.storage(UInt16.self)
        XCTAssertEqual(storageValue, 0x0004, "Storage function did not return the expected raw value for 16-bit enum.")
    }
    
    /// Validates that the enum correctly handles the maximum value representable with 16 bits for TestEnum16Bit.
    func testValidBoundaryValue16Bit() {
        let maxValue: UInt16 = 0xFFFF
        let valueFromStorage = TestEnum16Bit(storage: maxValue)
        XCTAssertEqual(valueFromStorage, .maxValue, "Enum should correctly handle max valid 16-bit value.")
    }
    
    /// Validates that the enum correctly handles the minimum value (0) for TestEnum16Bit.
    func testBoundaryConditionMin16Bit() {
        let minValue: UInt16 = 0
        let valueFromStorage = TestEnum16Bit(storage: minValue)
        XCTAssertEqual(valueFromStorage, .value0, "Enum should correctly handle minimum 16-bit value.")
    }
    
}
