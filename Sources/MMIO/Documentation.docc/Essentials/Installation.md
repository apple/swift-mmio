# Installation

Integrate Swift MMIO into your project using Swift Package Manager.

### Adding Swift MMIO as a Dependency

1. Open your `Package.swift` file.

2. Add Swift MMIO to the `dependencies` array of your `Package`:

  ```swift
  let package = Package(
    name: "MyApplication",
    dependencies: [
      // Add Swift MMIO package dependency
      .package(url: "https://github.com/apple/swift-mmio.git", from: "0.0.2"),
    ],
    //...
  ```

3. Add `MMIO` to the `dependencies` array of your `Package`:

  ```swift
  .executableTarget(
    name: "MyApplication",
    dependencies: [
      // Add the MMIO library as a dependency to your target
      .product(name: "MMIO", package: "swift-mmio"),
    ]),
  ```

4. After declaring the dependency, import `MMIO` in your Swift source files where you need to define or access MMIO registers:

    ```swift
    import MMIO
    ```

### Source Stability and Versioning

Swift MMIO follows semantic versioning. While the package is in major version `0` (e.g., `0.0.x`), source stability is only guaranteed within minor versions. For example, code written for `0.0.2` is compatible with `0.0.3`, but `0.1.0` might introduce source-breaking changes.

To protect your project against potentially source-breaking updates during the `0.x.y` development phase, specify your package dependency using the `.upToNextMinor(from:)` requirement:

```swift
.package(url: "https://github.com/apple/swift-mmio.git", .upToNextMinor(from: "0.0.2")),
```

This ensures that `swift package update` fetches compatible updates within the `0.0.x` series (e.g., `0.0.3`, `0.0.4`) but does not automatically update to `0.1.0` if it becomes available.
