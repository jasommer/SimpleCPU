	--------------------------------------------------------------------------------
	-- Company: 
	-- Engineer:
	--
	-- Create Date:   17:25:56 03/23/2020
	-- Design Name:   
	-- Module Name:   C:/Users/SernH/Desktop/Code Projects/FPGA/CPU/SimpleCPU/SimpleCPU/top_level_tb.vhd
	-- Project Name:  SimpleCPU
	-- Target Device:  
	-- Tool versions:  
	-- Description:   
	-- 
	-- VHDL Test Bench Created by ISE for module: top_level
	-- 
	-- Dependencies:
	-- 
	-- Revision:
	-- Revision 0.01 - File Created
	-- Additional Comments:
	--
	-- Notes: 
	-- This testbench has been automatically generated using types std_logic and
	-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
	-- that these types always be used for the top-level I/O of a design in order
	-- to guarantee that the testbench will bind correctly to the post-implementation 
	-- simulation model.
	--------------------------------------------------------------------------------
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;

	ENTITY top_level_tb IS
	END top_level_tb;

	ARCHITECTURE behavior OF top_level_tb IS 

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
		program_enab_in <= '1';
		instruction_in <= "000010000000"; --    RS-Vf 0x0, // save value 0 to address 0x9
		wait for clk_in_period;
		instruction_in <= "000000001001"; --    0x9 (ADDR)
		wait for clk_in_period;
		instruction_in <= "000010000001"; --    RS-Vf 0x1, // save value 1 to address 0xA
		wait for clk_in_period;
		instruction_in <= "000000001010"; --    0xA (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000001001"; --    RC-Af 0x9 // copy from 0x9 to 0x1
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    0x1 (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000001010"; --    RC-Af 0xA // copy from 0xA to 0x2
		wait for clk_in_period;
		instruction_in <= "000000000010"; --    0x2 (ADDR)
		wait for clk_in_period;
		instruction_in <= "011110000000"; --    ADD
		wait for clk_in_period;
		instruction_in <= "001000000011"; --    RC-Af 0x3 // copy result of addition from 0x3 to 0x8
		wait for clk_in_period;
		instruction_in <= "000000001000"; --    0x8 (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000000100"; --    RC-Af 0x4 // copy the alu flag output from 0x4 to 0x1
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    0x1 (ADDR)
		wait for clk_in_period;
		instruction_in <= "000010000001"; --    RS-Vf 0x1, // save value 1 to address 0x2 in order to apply a bitmask
		wait for clk_in_period;
		instruction_in <= "000000000010"; --    0x2(ADDR)
		wait for clk_in_period;
		instruction_in <= "100110000000"; --    AND // AND to get the overflow flag bit
		wait for clk_in_period;
		instruction_in <= "001000000011"; --    RC-Af 0x3 // copy result of the AND from 0x3 to 0x1
		wait for clk_in_period;
		instruction_in <= "000000000001"; --    0x1 (ADDR)
		wait for clk_in_period;
		instruction_in <= "000010000001"; --    RS-Vf 0x1, // save value 1 to address 0x2 in for comparision
		wait for clk_in_period;
		instruction_in <= "000000000010"; --    0x2(ADDR)
		wait for clk_in_period;
		instruction_in <= "010010011100"; --    JPE -- if overflow, go to HALT, else continue
		wait for clk_in_period;
		instruction_in <= "001000001000"; --    RC-Af 0x8 // copy from 0x8 to 0x0, the display
		wait for clk_in_period;
		instruction_in <= "000000000000"; --    0x0 (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000001010"; --    RC-Af 0xA // copy from 0xA to 0x9
		wait for clk_in_period;
		instruction_in <= "000000001001"; --    0x9 (ADDR)
		wait for clk_in_period;
		instruction_in <= "001000001000"; --    RC-Af 0x8 // copy from 0x8 to 0xA
		wait for clk_in_period;
		instruction_in <= "000000001010"; --    0xA (ADDR)
		wait for clk_in_period;
		instruction_in <= "001110000100"; --    JP to 0x4 (ADDR)
		wait for clk_in_period;
		instruction_in <= "111110000000"; --    HALT
		wait for clk_in_period;
		program_enab_in <= '0';
		
		wait for clk_in_period*3;
		rst_n_in <= '1';
		
		wait for clk_in_period*2000;
	  
	end process;

	END;
