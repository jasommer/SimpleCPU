----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:04:04 03/30/2020 
-- Design Name: 
-- Module Name:    ALU - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
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
	flags_out(0) <= '0' when (res_signed_ext(11) = res_signed(11)) else '1'; -- overflow flag
	flags_out(1) <= '1' when (res_signed = x"000") else '0';                 -- zero flag
	flags_out(2) <= '1' when (op1_in = op2_in) else '0';                     -- equality flag
	flags_out(3) <= error_state;                                             -- error flag
	
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

