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
-- Description:    Programs the SimpleCPU with program that iteratively computes the quotient of two numbers
	--------------------------------------------------------------------------------
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;

	ENTITY interative_division_tb IS
	END interative_division_tb;

	ARCHITECTURE behavior OF interative_division_tb IS 

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
        instruction_in <= "000110000000"; -- RS-ff 0xFFF, 0xFFF // initalize the stack pointer
		wait for clk_in_period;
		instruction_in <= "111111111111"; -- 
        wait for clk_in_period;
		instruction_in <= "111111111111"; -- 
		
        wait for clk_in_period;
		instruction_in <= "000100000110"; -- RS-Af 0x6, 0x21C // save value 0x21C (540 in decimal) at address 0x6 
		wait for clk_in_period;
		instruction_in <= "001000011100"; -- 
		
        wait for clk_in_period;
        instruction_in <= "000100000111"; -- RS-Af 0x7, 0x24   // save value 0x24 (36 in decimal) at address 0x7 
		wait for clk_in_period;
		instruction_in <= "000000100100"; -- 
        
        wait for clk_in_period;
        instruction_in <= "111010000001"; -- SSRR 0x1           // start subroutine at relative position 0x1
        wait for clk_in_period;
		instruction_in <= "111110000000"; -- HALT               // end program
        
        -- definition of the subroutine for iterative division
        -- takes two arguments: Operand1  at address 0x6 and Operand2 at address 0x8
        
        wait for clk_in_period;
		instruction_in <= "000100001000"; -- RS-Af 0x8, 0x1   // save inital counter value 0x1 to address 0x8                    
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
                
        wait for clk_in_period;
        instruction_in <= "001110000111"; -- RC-Af 0x7, 0x9    // initalize the intermediate value at 0x9 with the copy of Operand2 
		wait for clk_in_period;
		instruction_in <= "000000001001"; --
        
        wait for clk_in_period;
        instruction_in <= "001110000110"; -- RC-Af 0x6, 0x1    // copy Operand1 to OP1 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
        
        wait for clk_in_period;
        instruction_in <= "001110001001"; -- RC-Af 0x9, 0x2   // copy the intermediate value at 0x9 to OP2 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000010"; --
                
        wait for clk_in_period;
        instruction_in <= "100100011101"; -- JRE 0x1D         // if both operands are equal, then we are done. 
         
        wait for clk_in_period;
        instruction_in <= "001110001001"; -- RC-Af 0x9, 0x2   // copy the intermediate value at 0x9 to OP2 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000010"; --
        
        wait for clk_in_period;
        instruction_in <= "001110000111"; -- RC-Af 0x7, 0x1    // copy of Operand2 to OP1
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
        
        wait for clk_in_period;
        instruction_in <= "000100000011"; -- RS-Af 0x3, 0x1  // save value 0x1 to at address 0x3 in order to set the ALU to ADD mode 
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
        
        wait for clk_in_period;
        instruction_in <= "000000000000"; -- NOP              // wait for ALU
        
        wait for clk_in_period;
        instruction_in <= "001110000100"; -- RC-Af 0x4, 0x9   // copy result of the additon (at 0x4) to intermediate value at 0x9
		wait for clk_in_period;
		instruction_in <= "000000001001"; --
        
        wait for clk_in_period;
        instruction_in <= "001110000110"; -- RC-Af 0x6, 0x1    // copy Operand1 to OP1 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
        
        wait for clk_in_period;
        instruction_in <= "001110001001"; -- RC-Af 0x9, 0x2   // copy the intermediate value at 0x9 to OP2 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000010"; --
        
        wait for clk_in_period;
        instruction_in <= "000100000011"; -- RS-Af 0x3, 0xD  // save value 0xD to at address 0x3 in order to set the ALU to BGR mode
		wait for clk_in_period;
		instruction_in <= "000000001101"; --
                
        wait for clk_in_period;
        instruction_in <= "001110000100"; -- RC-Af 0x4, 0x1    // copy result of BGR operation to OP1 of the ALU
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    
        
        wait for clk_in_period;
        instruction_in <= "000100000010"; -- RS-Af 0x2, 0x0   // compare to 0 at OP2                  
		wait for clk_in_period;
		instruction_in <= "000000000000"; --
        
        wait for clk_in_period;
        instruction_in <= "000000000000"; -- NOP              // wait for ALU
        
        wait for clk_in_period;
        instruction_in <= "100100001000"; -- JRE 0x8          // if OP1 < OP2, then we are done.
        
        wait for clk_in_period;
        instruction_in <= "000100000011"; -- RS-Af 0xA, 0x3  // save value 0xA to at address 0x3 in order to set the ALU to INCR mode 
		wait for clk_in_period;
		instruction_in <= "000000001010"; --
        
        wait for clk_in_period;
        instruction_in <= "001110001000"; -- RC-Af 0x4, 0x7   // copy counter value (at 0x8) to op1 (0x1) in order to increment it
		wait for clk_in_period;
		instruction_in <= "000000000001"; --
        
        wait for clk_in_period;
        instruction_in <= "000000000000"; -- NOP              // wait for ALU
                
        wait for clk_in_period;
        instruction_in <= "001110000100"; -- RC-Af 0x4, 0x8   // update counter value (at 0x8)
		wait for clk_in_period;
		instruction_in <= "000000001000"; -- 
        
        wait for clk_in_period;
        instruction_in <= "011010001101"; -- JP 0xD         // jump to 0xD to repeat loop
        
        wait for clk_in_period;
        instruction_in <= "001110001000"; -- RC-Af 0x8, 0x0 // copy the result at address 0x8 to the display register at 0x0
        wait for clk_in_period;
        instruction_in <= "000000000000"; --     
                
        wait for clk_in_period;
        instruction_in <= "111100000000"; -- ESR            // escape subroutine
		
		wait for clk_in_period;
		
		program_enab_in <= '0'; -- end programming the instruction ROM
		wait for clk_in_period*3;
		rst_n_in <= '1'; -- start executing the program by setting the active low reset to high
		
		wait for clk_in_period*20000;
	  
	end process;

	END;
