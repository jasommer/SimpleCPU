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
-- Description:    simple synchronous implmentation of a ROM, that can only be programmed,
--                 if the write enable port wr_enab_in is set to high.
--
-- Dependencies:   N/A
--
-- Revision: 1.1
--
-----------------------------------------------------------------------------------

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

