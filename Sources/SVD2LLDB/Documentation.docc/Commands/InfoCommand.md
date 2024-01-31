# Info

Retrieve information about hardware items.

## Overview

The `svd info` command prints detailed information about one or more hardware items defined in an SVD file. This includes attributes such as addresses, sizes, access permissions, and other relevant details.

## Syntax

```console
USAGE: svd info <key-path> ...

ARGUMENTS:
  <key-path>              Key-path to a device, peripheral, cluster, register,
                          or field to get information about.

OPTIONS:
  -h, --help              Show help information.
```

## Examples

1. Print information about a specific register:

  ```console
  (lldb) svd info USART1.CR1
  USART1.CR1:
    Address:     0x4100_0004
    ResetValue:  0x0000_0000
    Description: The USART control register
    Fields:      [EN, RST]
  ```

2. Print information about a peripheral and multiple registers:

  ```console
  (lldb) svd info GPIOA GPIOA.MODER GPIOA.ODR
  GPIOA:
    Address:     0x4200_0000
    Description: The GPIO A pin bank control registers
    Registers:   [MODER, ODR, OSPEEDR]
  GPIOA.MODER:
    Address:     0x4100_0004
  ...
  ```

3. Print information about the top-level device:

  ```console
  (lldb) svd info .
  STM32F7x6
    ResetMask: 0xFFFF_FFFF
  ...
  ```
