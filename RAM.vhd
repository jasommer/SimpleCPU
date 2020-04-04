----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:57 03/29/2020 
-- Design Name: 
-- Module Name:    RAM - Behavioral 
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

entity RAM is
	generic (
			addr_size    : natural := 12;   -- address space = 2^addr_size
			word_size    : natural := 12
        );
    port ( 
			clk_in       : in  std_logic;
			wr_enab_in   : in  std_logic;
			addr_in      : in  std_logic_vector (addr_size-1 downto 0);
			data_in      : in  std_logic_vector (word_size-1 downto 0);
			data_out     : out std_logic_vector (word_size-1 downto 0);
			display_out  : out std_logic_vector (word_size-1 downto 0);
			
			-- ALU bus lines
			alu_op1_out  : out std_logic_vector (word_size-1 downto 0);
			alu_op2_out  : out std_logic_vector (word_size-1 downto 0);
			alu_flags_in : in  std_logic_vector (word_size-1 downto 0);
			alu_res_in   : in  std_logic_vector (word_size-1 downto 0)
		);
end RAM;

architecture Behavioral of RAM is
	
	type blockRam is array(0 to (2**addr_size)-1) of std_logic_vector(word_size-1 downto 0);
	signal ram : blockRam;
	
	-- special registers
	signal display   : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_op1   : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_op2   : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_res   : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	signal alu_flags : std_logic_vector (addr_size-1 downto 0) := (others => '0');
	
begin
	
	display_out <= display;
	alu_op1_out <= alu_op1;
	alu_op2_out <= alu_op2;
		
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
				data_out <= alu_res;
			elsif addr_in = x"004" then
				data_out <= alu_flags;
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
						display <= data_in;
					elsif addr_in = x"001" then
						alu_op1 <= data_in;
					elsif addr_in = x"002" then
						alu_op2 <= data_in;
					elsif addr_in = x"003" then
						-- read only!
					elsif addr_in = x"004" then
						-- read only!
					else
						ram(to_integer(unsigned(addr_in))) <= data_in;
					end if;	
			end if;
		end if;
	end process WRITE_RAM;

end Behavioral;

