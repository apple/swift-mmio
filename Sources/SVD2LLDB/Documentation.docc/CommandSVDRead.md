# Read

Read the current value of registers.

## Overview

The `svd read` command allows developers to access register values using their symbolic names. It supports reading registers within a peripheral cluster and ensures safe reading by default, only reading registers without read side-effects. Additionally, it provides an optional flag to force reading, ignoring side-effects.

## Syntax

```console
(lldb) svd read <key-path> ... [--force]
<key-path>     - A key-path to a peripheral, cluster, register, or field to read
                 the the value of.
[-f, --force]  - Always read registers ignoring side-effects.     
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
  warning: Skipping reads of registers with read side-effects. Use "--force" to read these registers.  
  USART1:
    CR1: 0x0000_0010
    CR2: 0xF0AC_0000
    SR:  0x0000_0000
    ISR: <skipped>
    ...
  ``` 

3. Read a peripheral with the `--force` flag, ensuring all registers are read, regardless of potential side-effects:

```console
(lldb) svd read USART1 --force
  USART1:
    CR1: 0x0000_0010
    CR2: 0xF0AC_0000
    SR:  0x0000_0000
    ISR: 0x0000_7000
  ...
``` 
