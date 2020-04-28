# SimpleCPU
A simple, fully synthesizable VHDL implementation of a general purpose 12 bit RISC CPU. This is not a highly complex FPGA project and should not be viewed as such - it is more of an educational attempt to practice and learn.

## Scope
As the name implies, the goal of this project was to come up with a processor architecture that is as
simple as possible while still beeing useful. This was achieved by the following design choices:
- a reduced instruction set that only uses 27 different instructions. This simplifies the instruction decoder architecture by a lot.
- Load-store data access. There is only one central memory for storing data, the RAM. 
  This means only a few instructions need to be implemented for manipulating memory and fewer bus lines and registers are needed.
  To access the ALU, the RAM addresses that are mapped to the ALU need to be written to/read from.
  This also means, that adding peripherals or I/O is just a matter of mapping them to memory without the need of new instructions.
- a simple control state machine that has no pipelining capabilities.
- simple addressing modes.

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
| Addressing modes | direct, indirect, PC-relative      |
| ALU operations | logical and signed integer arithmetic      |

## HDL Synthesis results
2  4096x12-bit single-port RAMs<br/>
3  12-bit adder    <br/>
1  12-bit subtractor <br/>
1  13-bit addsub<br/>
1  12-bit up counter<br/>
185 Registers<br/>
141 Multiplexers <br/>
2  Comparators <br/>
2  XORs<br/>
<br/>
## Place and Route results on the Spartan 6 xc6slx9 FPGA
Maximum frequency: 180 MHz <br/>
Number of Slice Registers: 212<br/>
Number of Slice LUTs:      498<br/>
Number of RAMB16BWERs:     6<br/>
<br/>
