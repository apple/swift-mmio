# Using the Command Line Tool

Generate Swift register interfaces from SVD files from the command line.

## Overview

The `svd2swift` command line tool allows you to transform an SVD file into a Swift register interface. It has a variety of options for configuring generated content, including peripheral selection, indentation, and namespacing. 

## Get Started

### Build svd2swift

Before using `svd2swift` you must first build it. This can be done in a couple simple steps:

> Important: This document refers to `svd2swift` in lowercase, however the product in SwiftPM is capitalized due to a build system quirk. This will be resolved in the future.

Clone the swift-mmio repository:

```console
$ git clone git@github.com:apple/swift-mmio.git
$ git checkout 0.0.2
```

Build `svd2swift` in release mode:

```console
$ swift build -c release --product SVD2Swift
```

Locate the tool in the build directory:

```console
$ ls $(swift build -c release --show-bin-path)/SVD2Swift
/Volumes/Developer/org.swift/swift-mmio/.build/arm64-apple-macosx/release/SVD2Swift
```

Finally, you can optionally install `svd2swift` into a convenient location in your `$PATH`.

```console
cp $(swift build -c release --show-bin-path)/SVD2Swift ~/bin
```

### Use the tool

Before using `svd2swift`, you need an SVD file, see <doc:Documentation#Find-your-device's-SVD-file> for suggestions on how to locate the SVD file for your device. 

With `svd2swift` now built you can use it to generate a register interface for your device. For example, using a hypothetical "device.svd" file, the simplest usage of `svd2swift` is:

```console
$ SVD2Swift -i device.svd -o Sources/Application
```

The resulting Swift source files are written to "Sources/Application". Add these files to your build and source control systems to include them in your application.

```console
$ ls Sources/Application
Project
╰╴Sources
  ╰╴Application
    ├─ Device.swift
    ├─ ADC0.swift
    ├─ ...
    └─ TIMER2.swift
```

If you'd like to avoid manually running `svd2swift` and including generated source files in source control, see <doc:UsingSVD2SwiftPlugin> for details on running `svd2swift` as part of your build.

## Option Reference

`svd2swift` supports a variety of options to customize the generated code. Read on for details about each of these options.

### Input

```console
-i, --input <input>
```

The input SVD file. Use '-' for stdin.

### Output

```console
-o, --output <output>
```

The output directory. Use '-' for stdout.

### Peripherals

```console
[-p, --peripherals <peripherals> ...]
```

The peripherals to include in the output. Skipping this option includes all peripherals in the output.

While it may be convenient to generate Swift interfaces for all device peripherals, it can slow down the compilation of your application. Reducing the generated code to only include the peripherals your application uses can significant improve compile times.

### Access Level

```console
[--access-level <access-level>]
```

The access level of generated Swift types. Skipping this option omits an access level modifier on generated declarations. (values: internal, public)

If you are generating register interfaces into a dedicated module, you will want to use `--access-level public` to ensure the types and instances are available to clients of the module.

### Indentation Width

```console
[--indentation-width <indentation-width>]
```

The number spaces to use for indentation. This option is only applicable when '--indent-using-tabs' is not used. (default: 4)

### Indent Using Tabs

```console
[--indent-using-tabs]
```

The indentation should use tabs.

### Namespace Under Device

```console
[--namespace-under-device]
```

The generated types and peripheral instances should be nested under a "device" type instead of defined at the top level scope.

Example diff:
```diff
- /// An example peripheral
- let examplePeripheral = ExamplePeripheral(unsafeAddress: 0x1000)
+ /// An example device
+ enum ExampleDevice {
+   /// An example peripheral
+   static let examplePeripheral = ExamplePeripheral(unsafeAddress: 0x1000)
+ }
```

### Instance Member Peripherals

```console
[--instance-member-peripherals]
```

The peripheral instances should be instance members of the device type. This option is only applicable when `--namespace-under-device` is used.

Example diff:
```diff
- enum ExampleDevice {
+ struct ExampleDevice {
-   static let examplePeripheral = ExamplePeripheral(unsafeAddress: 0x1000)
+   let exampleperipheral = ExamplePeripheral(unsafeAddress: 0x1000)
```

### Device Name

```console
[--device-name <device-name>]
```

A custom top-level device name. This option is only applicable when `--namespace-under-device-type` is used.

Example diff:
```diff
- enum ExampleDevice {
+ enum CustomDevice {
```
