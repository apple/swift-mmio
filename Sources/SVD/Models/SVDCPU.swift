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
public struct SVDCPU {
  /// Define the name of the processor.
  public var name: SVDCPUName
  /// Define the HW revision of the processor. The version format is rNpM
  /// (N,M = [0 - 99]).
  public var revision: SVDCPURevision
  /// Define the endianness of the processor.
  public var endian: SVDCPUEndianness
  /// Indicate whether the processor is equipped with a memory protection
  /// unit (MPU). This tag is either set to true or false, 1 or 0.
  public var mpuPresent: Bool
  /// Indicate whether the processor is equipped with a hardware floating
  /// point unit (FPU). Cortex-M4, Cortex-M7, Cortex-M33 and Cortex-M35P are
  /// the only available Cortex-M processor with an optional FPU. This tag is
  /// either set to true or false, 1 or 0.
  public var fpuPresent: Bool
  /// Indicate whether the processor is equipped with a double precision
  /// floating point unit. This element is valid only when `<fpuPresent>` is
  /// set to true. Currently, only Cortex-M7 processors can have a double
  /// precision floating point unit.
  public var fpuDP: Bool?
  /// Indicates whether the processor implements the optional SIMD DSP
  /// extensions (DSP). Cortex-M33 and Cortex-M35P are the only available
  /// Cortex-M processor with an optional DSP extension. For ARMv7M SIMD DSP
  /// extensions are a mandatory part of Cortex-M4 and Cortex-M7. This tag is
  /// either set to true or false, 1 or 0.. This element is mandatory for
  /// Cortex-M33, Cortex-M35P and future processors with optional SIMD DSP
  /// instruction set.
  public var dspPresent: Bool?
  /// Indicate whether the processor has an instruction cache. Note: only for
  /// Cortex-M7-based devices.
  public var icachePresent: Bool?
  /// Indicate whether the processor has a data cache. Note: only for
  /// Cortex-M7-based devices.
  public var dcachePresent: Bool?
  /// Indicate whether the processor has an instruction tightly coupled
  /// memory. Note: only an option for Cortex-M7-based devices.
  public var itcmPresent: Bool?
  /// Indicate whether the processor has a data tightly coupled memory. Note:
  /// only for Cortex-M7-based devices.
  public var dtcmPresent: Bool?
  /// Indicate whether the Vector Table Offset Register (VTOR) is implemented
  /// in Cortex-M0+ based devices. This tag is either set to true or false, 1
  /// or 0. If not specified, then VTOR is assumed to be present.
  public var vtorPresent: Bool?
  /// Define the number of bits available in the Nested Vectored Interrupt
  /// Controller (NVIC) for configuring priority.
  public var nvicPrioBits: UInt64
  /// Indicate whether the processor implements a vendor-specific System Tick
  /// Timer. If false, then the Arm-defined System Tick Timer is available.
  /// If true, then a vendor-specific System Tick Timer must be implemented.
  /// This tag is either set to true or false, 1 or 0.
  public var vendorSystickConfig: Bool
  /// Add 1 to the highest interrupt number and specify this number in here.
  /// You can start to enumerate interrupts from 0. Gaps might exist between
  /// interrupts. For example, you have defined interrupts with the numbers
  /// 1, 2, and 8. Add 9 :(8+1) into this field.
  public var deviceNumInterrupts: UInt64?
  /// Indicate the amount of regions in the Security Attribution Unit(SAU). If
  /// the value is greater than zero, then the device has a SAU and the
  /// number indicates the maximum amount of available address regions.
  public var sauNumRegions: UInt64?
  /// If the Secure Attribution Unit is preconfigured by HW or Firmware, then
  /// the settings are described here.
  public var sauRegionsConfig: SVDSAURegions?
}

extension SVDCPU: Decodable {}

extension SVDCPU: Encodable {}

extension SVDCPU: Equatable {}

extension SVDCPU: Hashable {}

extension SVDCPU: Sendable {}
