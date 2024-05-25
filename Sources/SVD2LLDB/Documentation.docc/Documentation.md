# ``SVD2LLDB``

An lldb plugin to enhance firmware debugging.

## Overview

Debugging firmware can be a challenging task, often involving tedious memory address manipulation and manual register inspection. This process can be error-prone and time-consuming, especially when dealing with complex hardware configurations.

`SVD2LLDB` is an [LLDB](https://lldb.llvm.org) plugin designed to enhance your debugging experience by providing semantic access to hardware registers in debug sessions. It leverages the `SVD` library to parse CMSIS SVD files, enabling you to interact with device registers by name rather than raw memory addresses and values.

## Examples

1. Load the SVD file corresponding to the target device:

  ```console
  (lldb) svd load ~/Downloads/STM32F7x6.svd
  Loaded SVD file: “STM32F7x6.svd”
  ```

2. Read the value of a hardware register using its name:

  ```console
  (lldb) svd read GPIOA.MODER
  GPIOA.MODER: 0x2800_0000
  ```

3. Modify the value of a hardware register using its name:

  ```console
  (lldb) svd write GPIOA.MODER 0x12345678
  GPIOA.MODER: 0x12345678
  ```

## Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

### Getting Started

- <doc:UsingSVD2LLDB>

### Commands

- <doc:LoadCommand>
- <doc:InfoCommand>
- <doc:ReadCommand>
- <doc:DecodeCommand>
- <doc:WriteCommand>
