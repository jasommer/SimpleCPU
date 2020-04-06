# SimpleCPU
A simple VHDL implementation of a general purpose 12 bit CPU for educational purposes. 

## Scope
As the name implies, the goal of this project was to come up with a processor architecture that is as
simple as possible while still beeing useful. This was achieved by the following design choices:
- a small instruction set

## Specifications overview:
| Type        | Specification           | 
| ------------- |:-------------:| 
| ISA type      | self-defined RISC | 
| Pipelining strategy     | no pipelining      | 
| Data access type      | Load-store      |
| Endianness      | Little endian      | 
| Word size | 12 bit      |
|Address size | 12 bit      |
| In-System RAM size | 6 kB       |
| In-System program memory | 6 kB      |
| Addressing mode | direct or PC-relative      |
| ALU operations | logical and signed integer arithmetic      |
