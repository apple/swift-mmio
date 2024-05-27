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

4. Decode the value `0x0123_4567` for register `TIMER0.CR` with a visual diagram: 

  ```console
  (lldb) svd decode TIMER0.CR 0x0123_4567 --visual
  TIMER0.CR: 0x0123_4567

                        ╭╴CNTSRC  ╭╴RST
    ╭╴S   ╭╴RELOAD╭╴CAPEDGE  ╭╴MODE
    ┴     ┴─      ┴─    ┴─── ┴──  ┴
  0b00000001001000110100010101100111
        ┬─    ┬─    ┬───    ┬   ┬─ ┬
        ╰╴IDR ╰╴TRGEXT      ╰╴PSC  ╰╴EN
                    ╰╴CAPSRC    ╰╴CNT

  [31:31] S       0x0 (STOP)
  [27:26] IDR     0x0 (KEEP)
  [25:24] RELOAD  0x1 (RELOAD1)
  [21:20] TRGEXT  0x2 (DMA2)
  [17:16] CAPEDGE 0x3
  [15:12] CAPSRC  0x4 (GPIOA_3)
  [11:8]  CNTSRC  0x5 (CAP_SRC_div32)
  [7:7]   PSC     0x0 (Disabled)
  [6:4]   MODE    0x6
  [3:2]   CNT     0x1 (Count_DOWN)
  [1:1]   RST     0x1 (Reset_Timer)
  [0:0]   EN      0x1 (Enable)
  ```

## Contributions

Contributions and feedback are welcome! Please refer to the [Contribution Guidelines](https://github.com/apple/swift-mmio#contributing-to-swift-mmio) for more information.

## Topics

### Getting Started

- <doc:BuildingSVD2LLDB>
- <doc:UsingSVD2LLDB>

### Commands

- <doc:LoadCommand>
- <doc:InfoCommand>
- <doc:ReadCommand>
- <doc:DecodeCommand>
- <doc:WriteCommand>
