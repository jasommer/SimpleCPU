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
-- Description:    simple synchronous implmentation of a RAM that can only be written to,
--                 if the write enable port wr_enab_in is set to high.
--                 It also features some special purpose memory mapped registers for accessing the ALU.
--                 these are: 
--
--                 display       at 0x000 which can be connected to 3 seven-segment displays (for debug purposes)
--                 alu_op1       at 0x001 which holds the 1st operand of the ALU
--                 alu_op2       at 0x002 which holds the 2nd operand of the ALU
--                 alu_opcode    at 0x003 which holds the opcode for the ALU
--                 alu_res       at 0x004 which holds the result of the ALU
--                 alu_flags     at 0x005 which holds the flags of the ALU
--                 stack_pointer at 0xFFF which holds the stack pointer for the return address stack (needed for subroutines)
--              
--                 Note that alu_res and alu_flags are read only! Writing to these registers simply does nothing.      
--
-- Dependencies:   N/A
--
-- Revision: 1.1
--
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
	generic (
			addr_size    : natural := 12;   -- address space = 2^addr_size
			word_size    : natural := 12
        );
    port ( 
			clk_in            : in  std_logic;
			wr_enab_in        : in  std_logic;
			addr_in           : in  std_logic_vector (addr_size-1 downto 0);
			data_in           : in  std_logic_vector (word_size-1 downto 0);
			data_out          : out std_logic_vector (word_size-1 downto 0);
			display_out       : out std_logic_vector (word_size-1 downto 0);
			stack_pointer_out : out std_logic_vector (word_size-1 downto 0);
			
			-- ALU bus lines
			alu_op1_out       : out std_logic_vector (word_size-1 downto 0);
			alu_op2_out       : out std_logic_vector (word_size-1 downto 0);
			alu_opcode_out    : out std_logic_vector (word_size-1 downto 0);
			alu_flags_in      : in  std_logic_vector (word_size-1 downto 0);
			alu_res_in        : in  std_logic_vector (word_size-1 downto 0)
		);
end RAM;

architecture Behavioral of RAM is
	
	type blockRam is array(0 to (2**addr_size)-1) of std_logic_vector(word_size-1 downto 0);
	signal ram : blockRam;
	
	-- special registers
	signal display       : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_op1       : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_op2       : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_opcode    : std_logic_vector (addr_size-1 downto 0) := x"001";
	signal alu_res       : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_flags     : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal stack_pointer : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	
begin
		
	display_out       <= display;
	alu_op1_out       <= alu_op1;
	alu_op2_out       <= alu_op2;
	alu_opcode_out    <= alu_opcode;
	stack_pointer_out <= stack_pointer;
		
	READ_RAM: process(clk_in) 
	begin
		if(rising_edge (clk_in)) then
			
			if    addr_in = x"000" then
				data_out <= display;
			elsif addr_in = x"001" then
				data_out <= alu_op1;
			elsif addr_in = x"002" then
				data_out <= alu_op2;
			elsif addr_in = x"003" then
				data_out <= alu_opcode;
			elsif addr_in = x"004" then
				data_out <= alu_res;
			elsif addr_in = x"005" then
			    data_out <= alu_flags;
			elsif addr_in = x"FFF" then
				data_out <= stack_pointer;
			else
				data_out <= ram(to_integer(unsigned(addr_in)));
			end if;	
			
			
		end if;
	end process READ_RAM; 
	
	WRITE_RAM: process(clk_in)
	begin
		if(rising_edge (clk_in)) then
				
				alu_flags   <= alu_flags_in;
				alu_res  	<= alu_res_in;
				
				if(wr_enab_in = '1') then
					
					if    addr_in = x"000" then
						display    <= data_in;
					elsif addr_in = x"001" then
						alu_op1    <= data_in;
					elsif addr_in = x"002" then
						alu_op2    <= data_in;
					elsif addr_in = x"003" then
						alu_opcode <= data_in;
					elsif addr_in = x"004" then
						-- read only!
					elsif addr_in = x"005" then
						-- read only!
					elsif addr_in = x"FFF" then
						stack_pointer <= data_in;
					else
						ram(to_integer(unsigned(addr_in))) <= data_in;
					end if;	
					
			end if;
		end if;
	end process WRITE_RAM;

end Behavioral;

