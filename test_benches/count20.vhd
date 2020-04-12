	--------------------------------------------------------------------------------
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
-- Description:    Programs the SimpleCPU with a counter that counts from 0 to 20
	--------------------------------------------------------------------------------
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;

	ENTITY count20 IS
	END count20;

	ARCHITECTURE behavior OF count20 IS 

	-- Component Declaration for the Unit Under Test (UUT)

	COMPONENT top_level
	PORT(
		 clk_in : IN  std_logic;
		 rst_n_in : IN  std_logic;
		 program_enab_in : IN  std_logic;
		 instruction_in : IN  std_logic_vector(11 downto 0)
		);
	END COMPONENT;


	--Inputs
	signal clk_in : std_logic := '0';
	signal rst_n_in : std_logic := '0';
	signal program_enab_in : std_logic := '0';
	signal instruction_in : std_logic_vector(11 downto 0) := (others => '0');

	-- Clock period definitions
	constant clk_in_period : time := 10 ns;

	BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: top_level PORT MAP (
		  clk_in => clk_in,
		  rst_n_in => rst_n_in,
		  program_enab_in => program_enab_in,
		  instruction_in => instruction_in
		);

	-- Clock process definitions
	clk_in_process :process
	begin
		clk_in <= '0';
		wait for clk_in_period/2;
		clk_in <= '1';
		wait for clk_in_period/2;
	end process;


	-- Stimulus process
	stim_proc: process
	begin			
		wait for (clk_in_period/2)*9;
		program_enab_in <= '1'; -- start programming the instructio ROM
		instruction_in <= "000010000000"; --    RS-Vf 0x0, // load start value 0 to addr 0x9
		wait for clk_in_period;
		instruction_in <= "000000001001"; --    0x9 (ADDR)
		wait for clk_in_period;
		instruction_in <= "000010000001"; --    RS-Vf 0x1, // load value 1 to addr 0x1 (OP1 of the ALU)
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    0x1 (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000001001"; --    RC-Af 0x9, // copy from addr 0x9 to addr 0x2 (OP2 of the ALU)
		wait for clk_in_period;
		instruction_in <= "000000000010"; --    0x2 (ADDR) 
		wait for clk_in_period;
		instruction_in <= "011110000000"; --    ADD	       // OP1 + OP2 
		wait for clk_in_period;
		instruction_in <= "001000000011"; --    RC-Af 0x3, // copy the result back to addr 0x9 
		wait for clk_in_period;
		instruction_in <= "000000001001"; --    0x9 (ADDR) 
		
		wait for clk_in_period;
		instruction_in <= "000010010100"; --    RS-Vf 0x14, // load the value 0x14 (=20) to addr 0x1 (OP1 of the ALU) 
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    0x1 (ADDR)
		
		wait for clk_in_period;
		instruction_in <= "001000001001"; --    RC-Af 0x9, // copy from addr 0x9 to addr 0x2 (op2 of the ALU)
		wait for clk_in_period;
		instruction_in <= "000000000010"; --    0x2 (ADDR)
		
		wait for clk_in_period;
		instruction_in <= "010010001111"; --    JPE       // jump to instruction 15 if OP1 == OP2
		
		wait for clk_in_period;
		instruction_in <= "001110000010"; --    JP        // jump to instruction 2
		
		wait for clk_in_period;
		instruction_in <= "111110000000"; --    HALT      // stop the program
		wait for clk_in_period;
		program_enab_in <= '0'; -- end programming the instructio ROM
		
		wait for clk_in_period*3;
		rst_n_in <= '1'; -- start the program by applying the active low reset
		
		wait for clk_in_period*2000;
	  
	end process;

	END;
