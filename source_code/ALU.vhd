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
			opcode     : in  std_logic_vector (4 downto 0);
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
	
begin
	
	-- extend and convert to signed
	op1_signed_ext <= resize(signed(op1_in), op1_signed_ext'length);
	op2_signed_ext <= resize(signed(op2_in), op2_signed_ext'length);
	
	-- assign flags
	flags_out(0) <= '1' when (res_signed_ext(11) xor res_signed(11)) else '1'; -- overflow flag
	flags_out(1) <= '1' when (res_signed = x"000") else '0';                   -- zero flag
	flags_out(2) <= '1' when (op1_in = op2_in) else '0';                       -- equality flag
	flags_out(3) <= error_state;                                               -- error flag
	
	-- output result
	res_signed   <= resize(res_signed_ext, res_out'length);
	res_out      <= std_logic_vector(res_signed); 
	
	ALU_BEHAV: process(clk_in) 
	begin
		if(rising_edge (clk_in)) then
			
			if    opcode = "01111" then -- ADD
				res_signed_ext <= op1_signed_ext + op2_signed_ext;
				
			elsif opcode = "10000" then -- SUB
				res_signed_ext <= op1_signed_ext - op2_signed_ext; 
				
			elsif opcode = "10001" then	-- LSFT 
				res_signed_ext <= shift_left(op1_signed_ext, 1);
				
			elsif opcode = "10010" then	-- RSFT
				res_signed_ext <= shift_right(op1_signed_ext, 1); 

			elsif opcode = "10011" then	-- AND
				res_signed_ext <= op1_signed_ext AND op2_signed_ext;

			elsif opcode = "10100" then	-- OR
				res_signed_ext <= op1_signed_ext OR op2_signed_ext;

			elsif opcode = "10101" then	-- XOR
				res_signed_ext <= op1_signed_ext XOR op2_signed_ext;

			elsif opcode = "10110" then	-- NAND
				res_signed_ext <= NOT (op1_signed_ext AND op2_signed_ext);

			elsif opcode = "10111" then	-- NOR
				res_signed_ext <= NOT (op1_signed_ext OR op2_signed_ext);

			elsif opcode = "11000" then	-- INCR
				res_signed_ext <= op1_signed_ext + 1;	

			elsif opcode = "11001" then	-- DECR
				res_signed_ext <= op1_signed_ext - 1;	

			elsif opcode = "11010" then	-- NOT
				res_signed_ext <= NOT op1_signed_ext;

			elsif opcode = "11011" then	-- BGR
				if(op1_signed_ext > op2_signed_ext) then
					res_signed_ext <= "0000000000001";
				else
					res_signed_ext <= "0000000000000";
				end if;
			
			elsif opcode = "11100" then	-- ABS
				if op1_signed_ext(12) = '1' then
					res_signed_ext <= (NOT op1_signed_ext) + 1;
				else
					res_signed_ext <= op1_signed_ext;
				end if;	
			
			elsif opcode = "11101" then -- L-LSFT
				-- logical shift requires unsigned argument. The result of the shift must then be reconverted to signed 
				--   and rezized in order to fit into res_signed_ext
				res_signed_ext <= resize(signed(shift_left(unsigned(op1_in), 1)), op1_signed_ext'length);
				
			elsif opcode = "11110" then -- L-RSFT
				res_signed_ext <= resize(signed(shift_right(unsigned(op1_in), 1)), op1_signed_ext'length);
			
			else
				if error_state = '0' then
					report "Undefined ALU opcode!" severity warning;
				end if;
				
				error_state <= '1';
				
			end if;
				
		end if;
	end process ALU_BEHAV;
	

end Behavioral;

