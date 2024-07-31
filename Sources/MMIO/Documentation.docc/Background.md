# Memory-Mapped Input/Output

An introduction to MMIO and register programming

## What is Memory-Mapped I/O?

Memory-Mapped Input/Output (MMIO) is a method that enables communication between a microcontroller's processor (CPU) and peripheral devices (peripherals). It involves mapping the device registers directly into the system's memory address space, allowing the CPU to interact with hardware devices using standard memory load and store instructions.

## Peripherals

Peripherals are discrete hardware devices inside a microcontroller separate from the CPU which allow the microcontroller to interact with it's external environment.

Peripherals include input devices like ADCs, output devices like LCD drivers, communication interfaces like UART, SPI, and I2C, storage devices like EEPROM and flash memory, and more.

Peripherals typically communicate several kinds of information with CPUs; control information to manage and configure the device’s operations, status information about their current state, error conditions, or progress of ongoing operations, and data information like incoming or outgoing data or raw sensor readings.

Peripherals present this information to the CPU as MMIO structures called "registers". 

## Memory Mapped Registers

Registers are the interfaces for configuring and controlling hardware peripherals through software. They are fixed-width collections of bits, each located at a specific memory address.


A Register is a fixed-width 


### Basic Operation

Software uses standard CPU load and store instructions to read from and write to registers respectively. These instructions must match the register's bit-width.

Although registers might seem similar to program memory, they function differently. When a CPU performs a load or store operation on a register's address, it does not access the system's main memory (like RAM). Instead, the operation is directed to the associated hardware device, which interprets the operation according to its own requirements.

Writing a value to a register cause data to be stored just like standard memory or it can immediate hardware actions, such as starting a data transfer or changing operational modes. Reading from a register can return the current status which can change between subsequent reads of the same address without any software interaction. FIXME note how this is different than typical memory. Accessing registers in MMIO can have immediate effects on peripheral behavior. Reading from or writing to a register can trigger hardware actions, such as starting a data transfer or altering operational modes. Some operations may require synchronization or waiting for specific hardware conditions to be met, which is managed through status registers.

The exact behavior of reads and writes for each bit is specific to each register.

### Structure and Access

Registers are typically designed to match the CPU's word size, which allows for straightforward read and write operations. Each register must always be accessed as a whole unit. 

### Fields

Inside a register, bits are grouped into "fields." Each field within a register is responsible for a specific function related to the hardware peripheral, such as enabling a feature, setting a mode, or reporting a status. Because registers are accessed via single load and store instructions, fields cannot be modified independently; any change affects the entire register.

Bit masks and bit shifts are common tools for setting or clearing individual fields.

** How to explain that you can a mutate field but you still read/write the entire register ** 

### Peripheral Device Organization

Peripheral devices often use separate registers for different functions. Control signals, data values, and status information are typically divided into distinct registers. This separation helps to logically and physically organize different aspects of the hardware and prevents unintentional mutation of control when operating on data.
