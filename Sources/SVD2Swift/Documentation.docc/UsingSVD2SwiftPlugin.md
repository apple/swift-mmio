# Using the SwiftPM Plugin

Generate Swift register interfaces from SVD files during of your SwiftPM build. 

## Overview

The `SVD2SwiftPlugin` integrates `svd2swift` into the SwiftPM build process, allowing you to exclude generated source code into your repository.

### Get Started

#### Setup Package.swift

First, add the Swift MMIO repository to your Package's dependencies:

```swift
.package(url: "https://github.com/apple/swift-mmio.git", from: "0.0.2"),
```

> Important: See [source stability](https://github.com/apple/swift-mmio#source-stability) for details on major version "0".

Second, add the `MMIO` library to your target's dependencies and the `SVD2SwiftPlugin` plugin to your target's plugins:

```swift
.executableTarget(
  name: "Application",
  dependencies: [
    .product(name: "MMIO", package: "swift-mmio")
  ],
  plugins: [
    .product(name: "SVD2SwiftPlugin", package: "swift-mmio")
  ]),
```

#### Add prerequisite files

Next, `SVD2SwiftPlugin` requires two accompanying files in order to generate code.

The first is an SVD file, see <doc:SVD2Swift#Find-your-device's-SVD-file> for suggestions on how to locate the SVD file for your device. The second is an "svd2swift.json" configuration file. `SVD2SwiftPlugin` uses to this file to determine what content to generate and allows you to customize the generated code. 

Both files should be placed in your target's "Sources" directory. For example, using the "Application" target from above and a hypothetical "device.svd" file, the file structure should look like:

```console
Project
├╴Package.swift
╰╴Sources
  ╰╴Application
    ├╴device.svd
    ├╴main.swift
    ╰╴svd2swift.json
```

#### Configure the plugin

Last, we need to tell `SVD2SwiftPlugin` how to generate code using the `svd2swift.json` file. Each option of the `SVD2SwiftPlugin` plugin corresponds to a command line flag of `svd2swift`.

| Configuration Key                                                                 | Type       | Required?  |
| --------------------------------------------------------------------------------- | ---------- | ---------- |
| [`peripherals`](<doc:UsingSVD2Swift#Peripherals>)                                 | `[String]` | ✔          | 
| [`access-level`](<doc:UsingSVD2Swift#Access-Level>)                               | `String`   | ✘          | 
| [`indentation-width`](<doc:UsingSVD2Swift#Indentation-Width>)                     | `Int`      | ✘          | 
| [`indent-using-tabs`](<doc:UsingSVD2Swift#Indent-Using-Tabs>)                     | `Bool`     | ✘          | 
| [`namespace-under-device`](<doc:UsingSVD2Swift#Namespace-Under-Device>)           | `Bool`     | ✘          | 
| [`instance-member-peripherals`](<doc:UsingSVD2Swift#Instance-Member-Peripherals>) | `Bool`     | ✘          | 
| [`device-name`](<doc:UsingSVD2Swift#Device-Name>)                                 | `String`   | ✘          | 

> Important: You **must** include a list of `peripherals` in your `svd2swift.json`. There is no "generate everything" option due to details of the SwiftPM build plugin implementation.
