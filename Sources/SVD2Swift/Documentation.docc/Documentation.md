# ``SVD2Swift``

Generate Swift register interfaces from SVD files. 

## Overview

The `MMIO` library allows you to express complex register interfaces directly in Swift source code without sacrificing on type-safety. However, writing register interfaces by hand can be tedious and error prone. 

Instead, the `svd2swift` and `SVD2SwiftPlugin`  tools allow you to generate a device's register interfaces using a [CMSIS](https://www.arm.com/technologies/cmsis) [SVD](https://arm-software.github.io/CMSIS_5/SVD/html/index.html) file.

If you'd like to write your own tool using the SVD format, see the ``SVD`` library.

### Get Started

#### Find your device's SVD file

Before using either tool code generation tool, you will need to find the SVD for your device. Vendors typically provide SVD files via their official websites. Look for a dedicated section for SVD files or download links.

Note that some vendors may require you to log in and/or agree to specific terms and conditions. Be sure to follow all vendor license requirements.

Additionally, make sure the file precisely matches your device model or device family. Debugging a mismatching register interface is an extremely time consuming and avoidable exercise.

#### Work around SVD inaccuracies

You may encounter issues with SVD files, such as inaccuracies or missing information. If you do, consider using [`svdtools`](https://github.com/rust-embedded/svdtools) provided by Rust Embedded Devices Working Group Tools team. `svdtools` is a collection of tools to modify vendor-supplied SVD files and contains community-sourced patches for many device models.

If you find an SVD file that fails to decode, please [create an issue](https://github.com/apple/swift-mmio/issues/new/choose) on the swift-mmio repository. 

#### Generate a Swift MMIO interface

Once you have an SVD file for your device, check out the `svd2swift` and `SVD2SwiftPlugin` tools to generate a Swift MMIO interface.

### Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

- <doc:UsingSVD2Swift>
- <doc:UsingSVD2SwiftPlugin>
