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
-- Description:    top level module that wraps all the functional modules and wires  
--                 them together. The input port program_enab_in can be set to high in order to program_enab_in
--                 the instruction ROM that holds the program to be executed. The instruction_in bus is for 
--                 transmitting the individual instructions to the instruction ROM. The display_out output is just
--                 for debug purposes (e.g. connecting 3 7-segment displays to it). 
--                 Note that the input rst_n_in expects an active low reset, but internally the reset is active high.                                
--
-- Dependencies:   ROM.vhd, RAM.vhd, ALU.vhd, control_unit.vhd, reset_bridge.vhd
--
-- Revision: 1.1
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
	generic (
			addr_size  : natural := 12;   -- address space = 2^addr_size
			word_size  : natural := 12
        );
    port ( 
			clk_in          : in std_logic;
			rst_n_in        : in std_logic; -- active low
			program_enab_in : in std_logic;
			instruction_in  : in std_logic_vector (addr_size-1 downto 0);
			display_out     : out std_logic_vector (addr_size-1 downto 0)
	);
end top_level;

architecture Behavioral of top_level is
	
	component reset_bridge
    port ( 
			clk_in         : in  std_logic;
			async_rst_n_in : in  std_logic;
			sync_rst_out   : out std_logic
		);
	end component;
	
	component ROM
    port(
		clk_in     : in  std_logic;
		wr_enab_in : in  std_logic;
		addr_in    : in  std_logic_vector(addr_size-1 downto 0);
		data_in    : in  std_logic_vector(addr_size-1 downto 0);
		data_out   : out std_logic_vector(addr_size-1 downto 0)
    );
    end component;
	
	component RAM
    port(
		clk_in       : in  std_logic;
		wr_enab_in   : in  std_logic;
		addr_in      : in  std_logic_vector(addr_size-1 downto 0);
		data_in      : in  std_logic_vector(addr_size-1 downto 0);
		data_out     : out std_logic_vector(addr_size-1 downto 0);
		display_out  : out std_logic_vector (word_size-1 downto 0);

		-- ALU bus lines
		alu_op1_out  : out std_logic_vector (word_size-1 downto 0);
		alu_op2_out  : out std_logic_vector (word_size-1 downto 0);
		alu_flags_in : in  std_logic_vector (word_size-1 downto 0);
		alu_res_in   : in  std_logic_vector (word_size-1 downto 0)
    );
    end component;
	
	component control_unit
	port( 
		clk_in             : in   std_logic;
		rst_in             : in   std_logic;
		program_enab_in    : in   std_logic;
		
		-- Instruction ROM control lines
		instr_rom_addr_out : out  std_logic_vector (addr_size-1 downto 0);
		instr_data_in      : in   std_logic_vector (addr_size-1 downto 0);
		
		-- RAM control lines
		ram_addr_out       : out  std_logic_vector (addr_size-1 downto 0);
		ram_data_in        : in   std_logic_vector (addr_size-1 downto 0);
		ram_data_out       : out  std_logic_vector (addr_size-1 downto 0);
		ram_wr_enab_out    : out  std_logic;
		
		-- ALU control lines
		alu_opcode_out     : out std_logic_vector (4 downto 0);
		alu_flags_in       : in  std_logic_vector (addr_size-1 downto 0)
	);
	end component;
	
	component ALU
	port ( 
		clk_in     : in  std_logic;
		opcode     : in  std_logic_vector (4 downto 0);
		op1_in     : in  std_logic_vector (addr_size-1 downto 0);
		op2_in     : in  std_logic_vector (addr_size-1 downto 0);
		res_out    : out std_logic_vector (addr_size-1 downto 0);
		flags_out  : out std_logic_vector (addr_size-1 downto 0)
	);
	end component;
	
	signal rst_internal : std_logic;
	
	-- instruction ROM bus signals
	signal rom_addr     : std_logic_vector(addr_size-1 downto 0);
	signal rom_data_out : std_logic_vector(addr_size-1 downto 0);
	
	-- RAM signals
	signal ram_addr     : std_logic_vector(addr_size-1 downto 0);
	signal ram_data_in  : std_logic_vector(addr_size-1 downto 0);  
	signal ram_data_out : std_logic_vector(addr_size-1 downto 0);
	signal ram_wr_enab  : std_logic;
	
	-- ALU signals
	signal alu_op1      : std_logic_vector(addr_size-1 downto 0);
	signal alu_op2      : std_logic_vector(addr_size-1 downto 0);
	signal alu_flags    : std_logic_vector(addr_size-1 downto 0);
	signal alu_res      : std_logic_vector(addr_size-1 downto 0);
	signal alu_opcode   : std_logic_vector(4 downto 0);
	
	signal display      : std_logic_vector(addr_size-1 downto 0);
	
begin
	
	display_out <= display;
	
	--------------------------------------------------------------------------
	------- reset bridge signals --------------------------------------------
	--------------------------------------------------------------------------
	reset_bridge_inst: reset_bridge
    port map ( 
		clk_in          => clk_in,
		async_rst_n_in  => rst_n_in,
		sync_rst_out    => rst_internal
	);
	
	--------------------------------------------------------------------------
	------- instruction ROM signals ------------------------------------------
	--------------------------------------------------------------------------
	 instruction_ROM_inst: ROM 
	 port map (
          clk_in     => clk_in,
          wr_enab_in => program_enab_in,
          addr_in    => rom_addr,
          data_in    => instruction_in,
          data_out   => rom_data_out
    );
	
	--------------------------------------------------------------------------
	------- RAM signals ------------------------------------------------------
	--------------------------------------------------------------------------
	RAM_inst: RAM 
	 port map (
          clk_in       => clk_in,
          wr_enab_in   => ram_wr_enab,
          addr_in      => ram_addr,
          data_in      => ram_data_in,
          data_out     => ram_data_out,
		  display_out  => display,
		  
		  -- ALU lines
		  alu_op1_out  => alu_op1,  
		  alu_op2_out  => alu_op2,  
		  alu_flags_in => alu_flags,
		  alu_res_in   => alu_res 
    );	                
	
	--------------------------------------------------------------------------
	------- control unit signals ---------------------------------------------
	--------------------------------------------------------------------------
	control_unit_inst: control_unit
	port map (
		clk_in             => clk_in,
		rst_in             => rst_internal,    
		program_enab_in    => program_enab_in,		
		
		-- Instruction ROM control lines
		instr_rom_addr_out => rom_addr,
		instr_data_in      => rom_data_out,
		
		-- RAM control lines
		ram_addr_out       => ram_addr,
		ram_data_in        => ram_data_out,
		ram_data_out       => ram_data_in,
		ram_wr_enab_out    => ram_wr_enab,
		
		-- ALU control lines
		alu_opcode_out    => alu_opcode,
		alu_flags_in      => alu_flags
	);
	
	--------------------------------------------------------------------------
	------- ALU signals ------------------------------------------------------
	--------------------------------------------------------------------------
	ALU_inst: ALU
	port map (
		clk_in    => clk_in,
		opcode    => alu_opcode, 
		op1_in    => alu_op1,   
		op2_in    => alu_op2,   
		res_out   => alu_res,
	    flags_out => alu_flags   
	);

end Behavioral;

