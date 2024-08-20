//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@testable import SVD
@testable import SVD2Swift

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SVD2SwiftTests {
  // This device has ~minimal content used only to validate output options.
  // Other tests should create their own device for targeted test cases.
  private static let testClusterOutputDevice = SVDDevice(
    name: "ExampleDevice",
    description: "An example device",
    addressUnitBits: 8,
    width: 32,
    registerProperties: .init(
      size: 32,
      access: .readWrite),
    peripherals: .init(
      peripheral: [
        .init(
          name: "ExamplePeripheral",
          description: "An example peripheral",
          baseAddress: 0x1000,
          registers: .init(
            cluster: [
              .init(
                name: "ExampleCluster1",
                description: "An example cluster level 1",
                addressOffset: 0x100,
                cluster: [
                  .init(
                    name: "ExampleCluster2",
                    description: "An example cluster level 2",
                    addressOffset: 0x30,
                    register: [
                      .init(
                        name: "ExampleCluster2Register",
                        description: "An example register in cluster 2",
                        addressOffset: 0x0)
                    ])
                ],
                register: [
                  .init(
                    name: "ExampleCluster1Register",
                    description: "An example register in cluster 1",
                    addressOffset: 0x10)
                ]),
              .init(
                name: "ExampleCluster1_1",
                description: "Another example cluster level 1",
                addressOffset: 0x200)
            ],
            register: [
              .init(
                name: "ExampleRegister",
                description: "An example register",
                addressOffset: 0x20,
                fields: .init(field: [
                  .init(
                    name: "ExampleField",
                    bitRange: .lsbMsb(.init(lsb: 4, msb: 10)))
                ]))
            ]))
      ]))

  func test_cluster_output() throws {
    XCTAssertSVD2SwiftOutput(
      svdDevice: Self.testClusterOutputDevice,
      options: .init(
        indentation: .space(2),
        accessLevel: nil,
        selectedPeripherals: [],
        namespaceUnderDevice: false,
        instanceMemberPeripherals: false,
        overrideDeviceName: nil),
      expected: [
        "Device.swift": """
        // Generated by svd2swift.

        import MMIO

        /// An example peripheral
        let exampleperipheral = ExamplePeripheral(unsafeAddress: 0x1000)

        """,

        "ExamplePeripheral.swift": """
        // Generated by svd2swift.

        import MMIO

        /// An example peripheral
        @RegisterBlock
        struct ExamplePeripheral {
          /// An example register
          @RegisterBlock(offset: 0x20)
          var exampleregister: Register<ExampleRegister>

          /// An example cluster level 1
          @RegisterBlock(offset: 0x100)
          var examplecluster1: ExampleCluster1

          /// Another example cluster level 1
          @RegisterBlock(offset: 0x200)
          var examplecluster1_1: ExampleCluster1_1
        }

        extension ExamplePeripheral {
          /// An example register
          @Register(bitWidth: 32)
          struct ExampleRegister {
            /// ExampleField
            @ReadWrite(bits: 4..<11)
            var examplefield: ExampleField
          }

          /// An example cluster level 1
          @RegisterBlock
          struct ExampleCluster1 {
            /// An example register in cluster 1
            @RegisterBlock(offset: 0x10)
            var examplecluster1register: Register<ExampleCluster1Register>
        
            /// An example cluster level 2
            @RegisterBlock(offset: 0x30)
            var examplecluster2: ExampleCluster2
          }
        
          /// Another example cluster level 1
          @RegisterBlock
          struct ExampleCluster1_1 {
          }
        }
        
        extension ExamplePeripheral.ExampleCluster1 {
          /// An example register in cluster 1
          @Register(bitWidth: 32)
          struct ExampleCluster1Register {
          }

          /// An example cluster level 2
          @RegisterBlock
          struct ExampleCluster2 {
            /// An example register in cluster 2
            @RegisterBlock(offset: 0x0)
            var examplecluster2register: Register<ExampleCluster2Register>
          }
        }

        extension ExamplePeripheral.ExampleCluster1.ExampleCluster2 {
          /// An example register in cluster 2
          @Register(bitWidth: 32)
          struct ExampleCluster2Register {
          }
        }

        """,
      ])
  }
}
