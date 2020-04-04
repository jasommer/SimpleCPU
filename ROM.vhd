----------------------------------------------------------------------------------
-- Create Date:    17:19:01 02/25/2020 
-- Description: instruction ROM
--
----------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM is
	generic (
			addr_size  : natural := 12;   -- address space = 2^addr_size
			word_size  : natural := 12
        );
    port ( 
			clk_in     : in  std_logic;
			wr_enab_in : in  std_logic;
			addr_in    : in  std_logic_vector (addr_size-1 downto 0);
			data_in    : in  std_logic_vector (word_size-1 downto 0);
			data_out   : out std_logic_vector (word_size-1 downto 0)
		);
end ROM;

architecture Behavioral of ROM is
	
	type blockRam is array(0 to (2**addr_size)-1) of std_logic_vector(word_size-1 downto 0);
	signal memory : blockRam; 
	
begin
	
	READ_ROM: process(clk_in) 
	begin
		if(rising_edge (clk_in)) then
			data_out <= memory(to_integer(unsigned(addr_in)));
		end if;
	end process READ_ROM; 
	
	PROGRAM_ROM: process(clk_in)
	begin
		if(rising_edge (clk_in)) then
			if(wr_enab_in = '1') then
				memory(to_integer(unsigned(addr_in))) <= data_in;
			end if;
		end if;
	end process PROGRAM_ROM;
	
	
end Behavioral;

