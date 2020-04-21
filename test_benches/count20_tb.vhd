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
-- Description:    Programs the SimpleCPU with a software that counts from 0 to 20 and 
--                 copys the intermediate results to the display register
	--------------------------------------------------------------------------------
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;

	ENTITY count20_tb IS
	END count20_tb;

	ARCHITECTURE behavior OF count20_tb IS 

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

  
	-- Stimulus process:  
	stim_proc: process
	begin			
		wait for (clk_in_period/2)*9;
		program_enab_in <= '1'; -- start programming the instruction ROM
		
--                         Machine code  |      Mnemonic     |    Comment	
	
		instruction_in <= "000010000000"; -- RS-Vf 0x0, 0x9  // inital value 0 saved at address 0x9
		wait for clk_in_period;
		instruction_in <= "000000001001"; -- 
		
		wait for clk_in_period;
		instruction_in <= "000010010100"; -- RS-Vf 0x1, 0x3  // set OP2 (at address 0x2) to 0x14
		wait for clk_in_period;
		instruction_in <= "000000000010"; -- 
		
		wait for clk_in_period;
		instruction_in <= "000010001010"; -- RS-Vf 0x1, 0x3  // set ALU to INCR mode
		wait for clk_in_period;
		instruction_in <= "000000000011"; -- 
		
		wait for clk_in_period;
		instruction_in <= "001110001001"; -- RC-Af 0x1, 0x1  // copy from address 0x9 to OP1 (at address 0x1)
		wait for clk_in_period;
		instruction_in <= "000000000001"; -- 
		
		wait for clk_in_period;
		instruction_in <= "001110000100"; -- RC-Af 0x4, 0x0  // copy ALU result (address 0x4) to display register (address 0x0)
		wait for clk_in_period;
		instruction_in <= "000000000000"; -- 
		
		wait for clk_in_period;
		instruction_in <= "001110000100"; -- RC-Af 0x4, 0x1  // copy ALU result (address 0x4) to OP1
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
		
		wait for clk_in_period;
		instruction_in <= "100000001110"; -- JPE             // jump to HALT instruction (at addr 0xE) if OP1=OP2

		wait for clk_in_period;
		instruction_in <= "011010001000"; -- JP              // jump to instruction at address 0x8	
		
		wait for clk_in_period;
		instruction_in <= "111110000000"; -- HALT            // end program
		wait for clk_in_period;
		
		program_enab_in <= '0'; -- end programming the instruction ROM
		wait for clk_in_period*3;
		rst_n_in <= '1'; -- start executing the program by setting the active low reset to high
		
		wait for clk_in_period*20000;
	  
	end process;

	END;
