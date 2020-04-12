# SimpleCPU
A simple VHDL implementation of a general purpose 12 bit CPU for educational purposes. 

## Scope
As the name implies, the goal of this project was to come up with a processor architecture that is as
simple as possible while still beeing useful. This was achieved by the following design choices:
- a reduced instruction set that only uses 32 different instructions. This simplifies the instruction decoder architecture by a lot.
- Load-store data access. There is only one central memory for storing data, the RAM. 
  This means only a few instructions need to be implemented for manipulating memory and fewer bus lines and registers are needed.
  To access the ALU, the RAM addresses that are mapped to the ALU need to be written to/read from.
  This also means, that adding peripherals or I/O is just a matter of mapping them to memory without the need of new instructions.
- a simple control state machine that has no pipelining capabilities.
- A simple direct or PC-relative addressing mode.

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

## HDL Synthesis results
2  4096x12-bit single-port RAMs<br/>
   2  12-bit adder    <br/>
   1  13-bit addsub<br/>
1  12-bit up counter<br/>
17 Registers<br/>
56 Multiplexers <br/>
2  Comparators <br/>
   1 1-bit xor2<br/>
   1 13-bit xor2<br/>
<br/>
## Place an Route results on the Spartan 6 xc6slx9 FPGA
Number of Slice Registers: 189<br/>
Number of Slice LUTs:      314<br/>
Number of RAMB16BWERs:     6<br/>
<br/>
