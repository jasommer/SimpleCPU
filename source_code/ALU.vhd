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
-- Description:    Synchronous Arithmetic Logic Unit (ALU) for 12-bit signed arithmetic.
--                 It calculates the result res_out by combining the two operands op1_in and op2_in
--                 depending on the opcode. The signal flags_out holds four diffrent flags.
-- 
--                 Operations:
--                 This ALU can perform additions, substractios and various logical operations
--                 (such as AND, XOR, etc). op1_in and op2_in are interpreted as signed integers in 2's complement representation.
--                 Therefore, this ALU can operate in a value range of +2047 to -2048.
--                 Note that there are two shift functions implemented, xSFT and L-xSFT, where the latter is a logical shift
--                 that also shifts the sign bit and the former is an arithmetic shift that keeps the sign bit.
--
--                 Functional description: 
--                 Prior to performing the operation, op1_in and op2_in are converted to signed and rezized by adding an extra bit.
--                 This extra bit is used for detecting overflows. After the synchronous operation is performed, 
--                 the result is rezized by removing the extra bit (but keeping the sign bit) and outputted though res_out.
--                 Overflows are detected by comparing the the 11th bit of the 13 bit res_signed_ext signal and 
--                 the 12 bit res_signed signal. If their 11th bit is not equal, we know that an overflow occured.   
--
--                 Flags:
--                 The overflow flag is 1 if the current opcode in combination with the two operands causes an over/underflow.
--                 The zero flag is 1 if the result of the operation is zero.
--                 The equality flag is 1 if both operands are equal.
--                 The error flag is 1 (and stays 1) if there ever was an undfined ALU opcode. This happens frequently
--                 during simulation when the opcode port is not driven and has the value "UUUUUUUUUUUU". 
--
-- Dependencies:   N/A
--
-- Revision: 1.1
--
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
	generic (
			addr_size  : natural := 12;   -- address space = 2^addr_size
			word_size  : natural := 12
        );
    port ( 
			clk_in     : in  std_logic;
			opcode     : in  std_logic_vector (addr_size-1 downto 0);
			op1_in     : in  std_logic_vector (addr_size-1 downto 0);
			op2_in     : in  std_logic_vector (addr_size-1 downto 0);
			res_out    : out std_logic_vector (addr_size-1 downto 0);
			flags_out  : out std_logic_vector (addr_size-1 downto 0)
		);
end ALU;

architecture Behavioral of ALU is
	
	signal res_signed     : signed (addr_size-1 downto 0) := (others => '0');
	signal op1_signed_ext : signed (addr_size downto 0) := (others => '0');
	signal op2_signed_ext : signed (addr_size downto 0) := (others => '0');
	signal res_signed_ext : signed (addr_size downto 0) := (others => '0');
	signal error_state    : std_logic := '0';	
	
	-- debug signals, for simulation only
	signal dbg_opcode_old : std_logic_vector (addr_size-1 downto 0) := x"000";
	signal dbg_opcode_changed : std_logic := '0';
	
begin
	
	-- extend and convert to signed
	op1_signed_ext <= resize(signed(op1_in), op1_signed_ext'length);
	op2_signed_ext <= resize(signed(op2_in), op2_signed_ext'length);
	
	-- assign flags
	flags_out(0) <= '0' when (res_signed_ext(11) = res_signed(11)) else '1';   -- overflow flag
	flags_out(1) <= '1' when (res_signed = x"000") else '0';                   -- zero flag
	flags_out(2) <= '1' when (op1_in = op2_in) else '0';                       -- equality flag
	flags_out(3) <= error_state;                                               -- error flag
	
	-- output result
	res_signed   <= resize(res_signed_ext, res_out'length);
	res_out      <= std_logic_vector(res_signed); 
	
	ALU_BEHAV: process(clk_in) 
	begin
		if(rising_edge (clk_in)) then
			
			if    opcode = x"001" then -- ADD
				assert dbg_opcode_changed = '0' report "ALU opcode set to ADD" severity note;
				res_signed_ext <= op1_signed_ext + op2_signed_ext;
				
			elsif opcode = x"002" then -- SUB
				assert (dbg_opcode_changed = '0') report "ALU opcode set to SUB" severity note;
				res_signed_ext <= op1_signed_ext - op2_signed_ext; 
				
			elsif opcode = x"003" then	-- LSFT 
				assert (dbg_opcode_changed = '0') report "ALU opcode set to LSFT" severity note;
				res_signed_ext <= shift_left(op1_signed_ext, 1);
				
			elsif opcode = x"004" then	-- RSFT	
				assert (dbg_opcode_changed = '0') report "ALU opcode set to RSFT" severity note;
				res_signed_ext <= shift_right(op1_signed_ext, 1); 

			elsif opcode = x"005" then	-- AND
				assert (dbg_opcode_changed = '0') report "ALU opcode set to AND" severity note;
				res_signed_ext <= op1_signed_ext AND op2_signed_ext;

			elsif opcode = x"006" then	-- OR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to OR" severity note;
				res_signed_ext <= op1_signed_ext OR op2_signed_ext;

			elsif opcode = x"007" then	-- XOR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to XOR" severity note;	
				res_signed_ext <= op1_signed_ext XOR op2_signed_ext;

			elsif opcode = x"008" then	-- NAND
				assert (dbg_opcode_changed = '0') report "ALU opcode set to NAND" severity note;
				res_signed_ext <= NOT (op1_signed_ext AND op2_signed_ext);

			elsif opcode = x"009" then	-- NOR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to NOR" severity note;
				res_signed_ext <= NOT (op1_signed_ext OR op2_signed_ext);

			elsif opcode = x"00A" then	-- INCR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to INCR" severity note;
				res_signed_ext <= op1_signed_ext + 1;	

			elsif opcode = x"00B" then	-- DECR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to DECR" severity note;
				res_signed_ext <= op1_signed_ext - 1;	

			elsif opcode = x"00C" then	-- NOT
				assert (dbg_opcode_changed = '0') report "ALU opcode set to NOT" severity note;
				res_signed_ext <= NOT op1_signed_ext;

			elsif opcode = x"00D" then	-- BGR
				assert (dbg_opcode_changed = '0') report "ALU opcode set to BGR" severity note;
				if(op1_signed_ext > op2_signed_ext) then
					res_signed_ext <= "0000000000001";
				else
					res_signed_ext <= "0000000000000";
				end if;
			
			elsif opcode = x"00E" then	-- ABS
				assert (dbg_opcode_changed = '0') report "ALU opcode set to ABS" severity note;
				if op1_signed_ext(12) = '1' then
					res_signed_ext <= (NOT op1_signed_ext) + 1; -- calc 2s complemet
				else
					res_signed_ext <= op1_signed_ext;
				end if;	
			
			elsif opcode = x"00F" then -- L-LSFT
				-- logical shift requires unsigned argument. The result of the shift must then be reconverted to signed 
				--   and rezized in order to fit into res_signed_ext
				assert (dbg_opcode_changed = '0') report "ALU opcode set to L-LSFT" severity note;
				res_signed_ext <= resize(signed(shift_left(unsigned(op1_in), 1)), op1_signed_ext'length);
				
			elsif opcode = x"010" then -- L-RSFT
				assert (dbg_opcode_changed = '0') report "ALU opcode set to L-RSFT" severity note;
				res_signed_ext <= resize(signed(shift_right(unsigned(op1_in), 1)), op1_signed_ext'length);
			
			else
				assert (dbg_opcode_changed = '0') report "Undefined ALU opcode asserted!" severity warning;
				error_state <= '1';
				
			end if;
				
		end if;
	end process ALU_BEHAV;
	
	DEBUG : process(clk_in)
	begin
		if rising_edge (clk_in) then
		
			if NOT(dbg_opcode_old = opcode) then
				dbg_opcode_old <= opcode;
			end if;
			
		end if;	
	end process DEBUG;

	dbg_opcode_changed <= '0' when (dbg_opcode_old = opcode) else '1';   
	
end Behavioral;

