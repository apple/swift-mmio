# Read

Read the value of registers.

## Overview

The `svd read` command allows you to read registers by name. It supports reading individual registers as well as dumping all registers within a peripheral or cluster. The command skips reading registers with side-effects by default to avoid unintentional modifications, and includes an optional flag to force reading, ignoring side-effects.

## Syntax

```console
USAGE: svd read <key-path> ... [--force]

ARGUMENTS:
  <key-path>              Key-path to a device, peripheral, cluster, register,
                          or field to get information about.

OPTIONS:
  --force                 Always read ignoring side-effects.
  -h, --help              Show help information.
```

## Examples

1. Read and print the values of multiple registers, simply provide their paths as arguments:

  ```console
  (lldb) svd read GPIOA.MODER GPIOA.ODR
  GPIOA.MODER: 0x2800_0000
  GPIOA.ODR:   0x0000_00FF
  ```

2. Read a peripheral and dump a tree structure of all registers and their values:

  ```console
  (lldb) svd read USART1
  warning: Skipping reads of registers with side-effects. Use "--force" to read these registers.
  USART1:
    CR1:  0x0000_0010
    CR2:  0xF0AC_0000
    SR:   0x0000_0000
    ISCR: <skipped>
  ...
  ```

3. Read a peripheral with the `--force` flag, ensuring all registers are read, regardless of potential side-effects:

  ```console
  (lldb) svd read USART1 --force
  USART1:
    CR1:  0x0000_0010
    CR2:  0xF0AC_0000
    SR:   0x0000_0000
    ISCR: 0x0000_7000
  ...
  ```
