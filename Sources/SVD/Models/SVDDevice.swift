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

#if canImport(FoundationXML)
import FoundationXML
#endif

@XMLElement
public struct SVDDevice {
  /// Specify the vendor of the device using the full name.
  public var vendor: String?
  /// Specify the vendor abbreviation without spaces or special characters.
  /// This information is used to define the directory.
  public var vendorID: String?
  /// The string identifies the device or device series. Device names are
  /// required to be unique.
  public var name: String
  /// Specify the name of the device series.
  public var series: String?
  /// Define the version of the SVD file. Silicon vendors maintain the
  /// description throughout the life-cycle of the device and ensure that all
  /// updated and released copies have a unique version string. Higher numbers
  /// indicate a more recent version.
  ///
  /// - Note: This property should technically be non-optional but some SVD
  ///         files in the wild are missing this field.
  public var version: String?
  /// Describe the main features of the device (for example: CPU, clock
  /// frequency, peripheral overview).
  ///
  /// - Note: This property should technically be non-optional but some SVD
  ///         files in the wild are missing this field.
  public var description: String?
  /// The text will be copied into the header section of the generated device
  /// header file and shall contain the legal disclaimer. New lines can be
  /// inserted by using `\n`. This section is mandatory if the SVD file is
  /// used for generating the device header file.
  public var licenseText: String?
  /// Describe the processor included in the device.
  public var cpu: SVDCPU?
  /// Specify the file name (without extension) of the device-specific system
  /// include file (`system_<device>.h`; See CMSIS-Core description). The
  /// header file generator customizes the include statement referencing the
  /// CMSIS system file within the CMSIS device header file. By default, the
  /// filename is `system_device-name.h`. In cases where a device series
  /// shares a single system header file, the name of the series shall be
  /// used instead of the individual device name.
  public var headerSystemFilename: String?
  /// This string is prepended to all type definition names generated in the
  /// CMSIS-Core device header file. This is used if the vendor's software
  /// requires vendor-specific types in order to avoid name clashes with other
  /// defined types.
  public var headerDefinitionsPrefix: String?
  /// Define the number of data bits uniquely selected by each address. The
  /// value for Cortex-M-based devices is 8 (byte-addressable).
  public var addressUnitBits: UInt64
  /// Define the number of data bit-width of the maximum single data transfer
  /// supported by the bus infrastructure. This information is relevant for
  /// debuggers when accessing registers, because it might be required to
  /// issue multiple accesses for resources of a bigger size. The expected
  /// value for Cortex-M-based devices is 32.
  public var width: UInt64
  /// Elements specify the default values for register size, access permission
  /// and reset value. These default values are inherited to all fields
  /// contained in this device.
  @XMLInlineElement
  public var registerProperties: SVDRegisterProperties = .init()
  /// Group to define peripherals.
  public var peripherals: SVDPeripherals
  // Unsupported:
  // /// The content and format of this section is unspecified. Silicon
  // /// vendors may choose to provide additional information. By default,
  // /// this section is ignored when constructing CMSIS files. It is up to
  // /// the silicon vendor to specify a schema for this section.
  // var vendorExtensions: [AnyHashable: Any]
}
