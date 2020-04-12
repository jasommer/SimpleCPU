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
-- Description:    The reset bridge generates a reset (rst_out) that is asynchronously asserted, but synchronously de-asserted,
--                 as proposed by Clifford Cummings.
--                 See http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_Resets.pdf for more info. 
--
-- Dependencies:   N/A
--
-- Revision: 1.1
--
-----------------------------------------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reset_bridge is
    port ( 
			clk_in         : in  std_logic;
			async_rst_n_in : in  std_logic;
			sync_rst_out   : out std_logic
		);
end reset_bridge;

architecture Behavioral of reset_bridge is
	
	signal flip_flop      : std_logic;
	signal rst_n_internal : std_logic;
	
begin
	
	sync_rst_out <= NOT rst_n_internal;
	
	RESET_BEHAV: process (clk_in, async_rst_n_in)
	begin
	
		if (async_rst_n_in = '0') then
			flip_flop      <= '0';
			rst_n_internal <= '0';
			
		elsif rising_edge(clk_in) then
			flip_flop      <= '1';
			rst_n_internal <= flip_flop;
			
		end if;
		
	end process RESET_BEHAV;
	
end Behavioral;

