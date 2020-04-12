# SimpleCPU documentation

## Overview


## ISA
| Opcode        | Mnemonic      | Explanation      |
| ------------- |:-------------:| :-------------:| 
|0	|NOP	|No Operation
|1	|RS-Vf	|Save 7 bit value to RAM to follow-up address                                            |
|2	|RS-Af	|Save to 7 bit RAM address the follow-up value                                           |
|3	|RS-ff	|Save 12 bit follow-up value to 12-bit follow-up address                                 |
|4	|RC-Af	|Copy value from 7 bit address1 to follow up address2                                    |
|5	|RC-fA	|Copy value from follow-up address1 to 7 bit address2                                    |
|6	|RC-ff	|Copy value from follow-up address to follow-up address                                  |
|7	|JP	    |Direct Jump. Set instruction counter to 7 bit value                                     |
|8	|JP-f	|Direct Jump. Set instruction counter to 12 bit follow-up value                          |
|9	|JPE	|Direct Jump. If OP1 = OP2, set instruction counter to 7 bit value                       |
|A	|JPE-f	|Direct Jump. If OP1 = OP2, set instruction counter to 12 bit follow-up value            |
|B	|JR     |Relative jump. Add  7 bit value to instruction counter                                  |
|C	|JRE	|Relative jump. If OP1 = OP2, add  7 bit value to instruction counter                    |
|D	|UNDEFINED| N/A	                                                                                 |
|E	|UNDEFINED| N/A                                                                                  | 
|F	|ADD	|OP1+OP2                                                                                 | 
|10	|SUB	|OP1-OP2                                                                                 | 
|11	|LSFT	|OP1<<1 (arithmetic)                                                                     | 
|12	|RSFT	|OP1<<1 (arithmetic)                                                                     | 
|13	|AND	|OP1 AND OP2                                                                                 | 
|14	|OR	    |OP1 OR OP2                                                                                 | 
|15	|XOR	|OP1 XOR OP2                                                                                 | 
|16	|NAND	|!(OP1 AND OP2)                                                                              | 
|17	|NOR	|!(OP1 OR OP2)                                                                              | 
|18	|INCR	|OP1+1                                                                                   | 
|19	|DECR	|OP1-1                                                                                   | 
|1A	|NOT	|NOT OP1                                                                                    | 
|1B	|BGR	|returns 1 if OP1>OP2 else 0                                                                                | 
1C	|ABS	|Absolute(OP1)                                                                                   | 
1D	|L-LSFT	|OP1<<1 (logical)                                                                        | 
1E	|L-RSFT	|OP1>>1 (logical)                                                                        | 
1F	|HALT	|Stops the program                                                                       |


## Functional description
