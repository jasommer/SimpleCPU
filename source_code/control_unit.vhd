----------------------------------------------------------------------------------
--
--  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
--  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
--  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
--  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
--  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
--  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
--  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 
--
-- Copyright (C) 2020 Jan Sommer
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
-- 
-- Project Name:   SimpleCPU
-- Description:    The control unit of the CPU. It mainly consits of a state machine called
--                 CONTROL_UNIT_FSM_BEHAV and operates as follows:
--
--                 - in state FETCH1 it fetches the next instruction from the instruction ROM by 
--                   sending the value uf the counter instruction_cntr_out as an address to instr_rom_addr_out.
--                   The response of the instruction ROM is saved in the register instruction_reg.    
--
--                 - in the DECODE state, the instruction in instruction_reg is decoded. This is done by
--                   looking at the 5 bit opcode which is located at bits 11 to 7 of the 12 bit instruction.
--
--                 - the instruction is then executed in the stages 1 to 3 (EXECUTE_S1, EXECUTE_S2, EXECUTE_S3).
--                   Depending on the instruction itself, some instructions need all three stages (e.g. RS-ff), 
--                   some might only need one (e.g. JP).
--
--                 - HALT is a special state that can be used to stall the state machine (e.g. when the program has terminated.)
--                   In the case of an error (an unknown opcode), the state machine will also jump to the HALT state.
--                   The HALT state can only be escaped when a reset is applied.
--
--                 The if an operation should be executed by the ALU, the control unit will formward the correct ALU-opcode
--                 to it via the alu_opcode_out bus. Note that the operands and the result of the ALU are memory-mapped to the RAM.
--                 The control unit has direct access to the alu_flags_in bus of the ALU. This is needed for the 
--                 Jump-If-Equal instructions (JPE and JPE-f). The control unit will just check if the equality flag is set and
--                 then execute the jump accordingly.
--
--                 Some notes on the programming phase. If program_enab_in is set to high, The control unit will start to program 
--                 the instruction ROM. As long as program_enab_in is enabled, the control unit FSM is held in reset.
--                 For programming instruction_cntr_out is assigned to the counter instruction_cntr_prgrm (during the normal
--                 execution instruction_cntr_run is used). The control unit expectes that with every clk_in rising edge, 
--                 a new instruction is delivered via the instruction_in bus (as long as program_enab_in is high). 
--                 Therefore instruction_cntr_prgrm is incremented every rising edge.
--
--                                            program_enab_in
--                                                   │ 
--                                         ╔═════════╧════════════╗ 
--                   instruction_cntr_run──╢ [0]                  ║ 
--                                         ║ INSTRUCTION_CNTR_MUX ╟──instruction_cntr_out
--                 instruction_cntr_prgrm──╢ [1]                  ║ 
--                                         ╚══════════════════════╝
--
-- Dependencies:   N/A
--
-- Revision: 1.1
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_unit is
	generic (
			addr_size  : natural := 12;   -- address space = 2^addr_size
			word_size  : natural := 12
        );
	port( 
			clk_in             : in   std_logic;
            rst_in             : in   std_logic;
			program_enab_in    : in   std_logic; -- set to 1 to program the instruction ROM
			
			-- Instruction ROM control lines
            instr_rom_addr_out : out  std_logic_vector (addr_size-1 downto 0);
            instr_data_in      : in   std_logic_vector (addr_size-1 downto 0);
			
			-- RAM control lines
            ram_addr_out       : out  std_logic_vector (addr_size-1 downto 0);
            ram_data_in        : in   std_logic_vector (addr_size-1 downto 0);
            ram_data_out       : out  std_logic_vector (addr_size-1 downto 0);
            ram_wr_enab_out    : out  std_logic; -- write enable
			
			-- ALU control lines
			alu_opcode_out     : out std_logic_vector (4 downto 0);
			alu_flags_in       : in  std_logic_vector (addr_size-1 downto 0)
		);
end control_unit;

architecture Behavioral of control_unit is

	signal instruction_cntr_prgrm   : unsigned (addr_size-1 downto 0) := (others => '0');
	signal instruction_cntr_run     : unsigned (addr_size-1 downto 0) := (others => '0');
	signal instruction_cntr_run_new : unsigned (addr_size-1 downto 0) := (others => '0');
	signal instruction_cntr_out     : unsigned (addr_size-1 downto 0) := (others => '0');
	signal instruction_reg          : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	
	signal opcode                   : std_logic_vector (4 downto 0) := (others => '0');
	signal payload                  : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	
	signal rst_internal             : std_logic;
	signal follow_up_reg1           : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	
	type state_type is (FETCH1, DECODE, EXECUTE_S1, EXECUTE_S2, EXECUTE_S3, HALT);  
	signal control_unit_state       : state_type := FETCH1;
		
begin
	
	instruction_cntr_run_new <= instruction_cntr_run + 1;
	instr_rom_addr_out       <= std_logic_vector(instruction_cntr_out);
	opcode                   <= instruction_reg(addr_size-1 downto addr_size-5); -- in a 12 bit instruction bits 11 to 7 define the opcode
	payload                  <= (payload'left downto 7 => '0') & instruction_reg(addr_size-6 downto 0); -- bits 6 to 0 hold the payload
		
	CONTROL_UNIT_FSM_BEHAV: process(clk_in, rst_internal)
	begin 
		if(rst_internal = '1') then
			instruction_cntr_run <= (others => '0');
			ram_wr_enab_out      <= '0';
			control_unit_state   <= FETCH1;
		else
			if rising_edge(clk_in) then 
			
				case control_unit_state is
				
					when FETCH1 =>
						instruction_reg      <= instr_data_in;
						instruction_cntr_run <= instruction_cntr_run_new;
						control_unit_state   <= DECODE;
						ram_wr_enab_out      <= '0';
						
					when DECODE =>
						
						if    opcode = "00000" then -- NOP
							report "NOP" severity note;
							control_unit_state <= FETCH1;
							
						elsif opcode = "00001" then -- RS-Vf
							report "RS-Vf" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S1;
														
						elsif opcode = "00010" then -- RS-Af
							report "RS-Af" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S1;
													
						elsif opcode = "00011" then -- RS-ff
							report "RS-ff" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S1;
						
						elsif opcode = "00100" then -- RC-Af
							report "RC-Af" severity note;
							ram_addr_out <= payload;
							control_unit_state <= EXECUTE_S1;
							
						elsif opcode = "00101" then -- RC-fA
							report "RC-fA" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S1;	
						
						elsif opcode = "00110" then -- RC-ff
							report "RC-ff" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S1;
						
						elsif opcode = "00111" then -- JP
							report "JP" severity note;
							report "   -jumping to address " & integer'image(to_integer(unsigned(payload)));
							instruction_cntr_run <= unsigned(payload);
							control_unit_state   <= EXECUTE_S1;
							
						elsif opcode = "01000" then -- JP-f
							report "JP-f" severity note;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state   <= EXECUTE_S1;	
						
						elsif opcode = "01001" then -- JPE
							report "JPE" severity note;
							
							if(alu_flags_in(2) = '1') then -- check the alu equality flag
								report "   -jumping" severity note;
								instruction_cntr_run <= unsigned(payload);
								control_unit_state   <= EXECUTE_S1;
							else
								report "   -not jumping" severity note;
								control_unit_state   <= FETCH1;
							end if;
							
						elsif opcode = "01010" then -- JPE-f
							report "JPE-f" severity note;
							
							if(alu_flags_in(2) = '1') then -- check the alu equality flag
								report "   -jumping" severity note;
								instruction_cntr_run <= instruction_cntr_run_new;
								control_unit_state   <= EXECUTE_S1;
							else
								report "   -not jumping" severity note;
								control_unit_state   <= EXECUTE_S1;
							end if;
							
						elsif opcode = "01111" then -- ADD
							report "ADD" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10000" then -- SUB
							report "SUB" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;
						
						elsif opcode = "10001" then -- LSFT
							report "LSFT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10010" then -- RSFT
							report "RSFT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10011" then -- AND
							report "AND" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10100" then -- OR
							report "OR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10101" then -- XOR
							report "XOR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10110" then -- NAND
							report "NAND" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "10111" then -- NOR
							report "NOR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;	
						
						elsif opcode = "11000" then -- INCR
							report "INCR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;
							
						elsif opcode = "11001" then -- DECR
							report "DECR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "11010" then	-- NOT	
							report "NOT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;
							
						elsif opcode = "11010" then	-- NOT	
							report "NOT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "11011" then	-- BGR	
							report "BGR" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "11100" then	-- ABS	
							report "ABS" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "11101" then	-- L-LSFT	
							report "L-LSFT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;

						elsif opcode = "11110" then	-- R-LSFT	
							report "R-LSFT" severity note;
							alu_opcode_out <= opcode;
							control_unit_state <= FETCH1;		
							
						elsif opcode = "11111" then -- HALT
							report "HALT" severity note;
							control_unit_state <= HALT;
							
						else 
							report "Undefined opcode!" severity warning;
							control_unit_state <= HALT;
							
						end if;
					
					when EXECUTE_S1 =>
						
						if    opcode = "00001" then -- RS-Vf
							report "   -save value " & integer'image(to_integer(unsigned(payload))) & " to address " & integer'image(to_integer(unsigned(instr_data_in)));
							ram_addr_out <= instr_data_in;
							ram_data_out <= payload;
							ram_wr_enab_out <= '1'; -- write to RAM
							control_unit_state <= FETCH1;
						
						elsif opcode = "00010" then -- RS-Af
							report "   -save value " & integer'image(to_integer(unsigned(instr_data_in))) & " to address " & integer'image(to_integer(unsigned(payload)));
							ram_addr_out <= payload;
							ram_data_out <= instr_data_in;
							ram_wr_enab_out <= '1'; -- write to RAM
							control_unit_state <= FETCH1;
						
						elsif opcode = "00011" then -- RS-ff
							follow_up_reg1 <= instr_data_in; -- save intermediate value to follow_up_reg1
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S2;
							
						elsif opcode = "00100" then -- RC-Af
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S2;
						
						elsif opcode = "00101" then -- RC-fA
							ram_addr_out <= instr_data_in;
							control_unit_state <= EXECUTE_S2;
							
						elsif opcode = "00110" then -- RC-ff
							report "   -copy from address " & integer'image(to_integer(unsigned(instr_data_in))); 
							ram_addr_out <= instr_data_in;
							instruction_cntr_run <= instruction_cntr_run_new;
							control_unit_state <= EXECUTE_S2;
							
						elsif opcode = "00111" then -- JP
							control_unit_state <= FETCH1;
							
						elsif opcode = "01000" then -- JP-f
							report "   -jumping to address " & integer'image(to_integer(unsigned(instr_data_in)));
							instruction_cntr_run <= unsigned(instr_data_in);
							control_unit_state   <= EXECUTE_S2;
						
						elsif opcode = "01001" then -- JPE
							control_unit_state <= FETCH1;
						
						elsif opcode = "01010" then -- JPE-f
							report "   -jumping to address " & integer'image(to_integer(unsigned(instr_data_in)));
							instruction_cntr_run <= unsigned(instr_data_in);
							control_unit_state   <= EXECUTE_S2;
						
						end if;
					
					when EXECUTE_S2 =>
												
						if    opcode = "00011" then -- RS-ff
							report "   -save value " & integer'image(to_integer(unsigned(follow_up_reg1))) & " to address " & integer'image(to_integer(unsigned(instr_data_in)));
							ram_addr_out <= instr_data_in;
							ram_data_out <= follow_up_reg1;
							ram_wr_enab_out <= '1';
							control_unit_state <= FETCH1;
							
						elsif opcode = "00100" then -- RC-Af
							report "   -copy from address " & integer'image(to_integer(unsigned(payload))) & " to address " & integer'image(to_integer(unsigned(instr_data_in)));
							ram_addr_out <= instr_data_in;
							ram_data_out <= ram_data_in;
							ram_wr_enab_out <= '1';
							control_unit_state <= FETCH1;
						
						elsif opcode = "00101" then -- RC-fA
							report "   -copy from address " & integer'image(to_integer(unsigned(instr_data_in))) & " to address " & integer'image(to_integer(unsigned(payload)));
							ram_addr_out <= payload;
							ram_data_out <= ram_data_in;
							ram_wr_enab_out <= '1';
							control_unit_state <= FETCH1;
						
						elsif opcode = "00110" then -- RC-ff
							report "    to address " & integer'image(to_integer(unsigned(instr_data_in)));
							ram_addr_out <= instr_data_in;
							ram_data_out <= ram_data_in;
							ram_wr_enab_out <= '1';
							control_unit_state <= FETCH1;
						
						elsif opcode = "01000" then -- JP-f
							control_unit_state <= FETCH1;
							
						elsif opcode = "01010" then -- JPE-f	
							control_unit_state <= FETCH1;
							
						end if;
						
					when EXECUTE_S3 =>
						if    opcode = "00011" then -- RS-ff
							control_unit_state <= FETCH1;
						end if;	
						
					when HALT =>
						-- Do nothing, wait for reset
					
					when others =>
						report "undefined state!" severity warning;
					
				end case;
				
			end if;
		end if;
	end process CONTROL_UNIT_FSM_BEHAV;
	
	INSTRUCTION_CNTR_MUX: process(program_enab_in, instruction_cntr_prgrm, instruction_cntr_run)
	begin
		if(program_enab_in = '1') then 
			instruction_cntr_out <= instruction_cntr_prgrm; -- when programming the instruction ROM use instruction_cntr_prgrm
		else 
			instruction_cntr_out <= instruction_cntr_run;   -- else, use instruction_cntr_run
		end if;
	end process INSTRUCTION_CNTR_MUX;
	
	INSTRUCTION_CNTR_PRGRM_BEHAV: process(clk_in, program_enab_in)
	begin
		if rising_edge(clk_in) then
		
			if(program_enab_in = '1') then
				instruction_cntr_prgrm <= instruction_cntr_prgrm + 1;
			else 
				instruction_cntr_prgrm <= (others => '0');
			end if;
		
		end if;
	end process INSTRUCTION_CNTR_PRGRM_BEHAV;
	
	
	RST_BEHAV: process(rst_in, program_enab_in)
	begin
		if(program_enab_in = '0') then 
			-- hold on reset when programming
			rst_internal <= rst_in;
		else
			rst_internal <= '1';
		end if;			
	end process RST_BEHAV;
	
end Behavioral;

