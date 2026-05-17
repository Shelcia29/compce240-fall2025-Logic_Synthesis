-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 09
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synthesizer.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 10.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Synthesiszer top level
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity synthesizer is

	generic (
    		data_width_g : integer := 16;
            clk_freq_g: integer := 12288000;
            sample_rate_g : integer := 48000;
            n_keys_g : integer := 4
  	);
  
	port (
    		clk     : in  std_logic;
    		rst_n   : in  std_logic;
            keys_in : in std_logic_vector(n_keys_g - 1 downto 0);
            aud_bclk_out : out std_logic;
            aud_data_out : out std_logic;
            aud_lrclk_out : out std_logic
  	);

end synthesizer;

architecture structural of synthesizer is

  -- internal signals
  	signal wave_out_bus : std_logic_vector((n_keys_g*data_width_g)-1 downto 0);
  	signal sum_out_bus  : std_logic_vector(data_width_g-1 downto 0);

  -- component declarations
  	component wave_gen

		generic (
    		width_g : integer := 4;
            step_g : integer := 2 
  		);
		port (
            clk     : in  std_logic;
    		rst_n   : in  std_logic;
    		sync_clear_n_in : in std_logic;
    		value_out : out std_logic_vector(width_g-1 downto 0) 
		);

  	end component;

  	component multi_port_adder

		generic (
    		operand_width_g : integer := 16;
    		num_of_operands_g : integer := 4
  		);
  		port (
    		clk     : in  std_logic;
    		rst_n   : in  std_logic;
    		operands_in : in std_logic_vector ((operand_width_g*num_of_operands_g)-1 downto 0);
    		sum_out : out std_logic_vector(operand_width_g-1 downto 0)
		);

	end component;

	component audio_ctrl

 	 	generic (
    		ref_clk_freq_g : integer := 12288000; 
    		sample_rate_g  : integer := 48000;     
    		data_width_g   : integer := 16         
  		);

  		port (
    		clk          : in  std_logic;
    		rst_n        : in  std_logic;
    		left_data_in : in  std_logic_vector(data_width_g-1 downto 0);
    		right_data_in: in  std_logic_vector(data_width_g-1 downto 0);

    		aud_bclk_out : out std_logic;
    		aud_lrclk_out: out std_logic;
    		aud_data_out : out std_logic
  		);
	end component;

begin

--instantiate 4 wave generators
	wave_gen_0 : wave_gen
    	generic map (
      		width_g => data_width_g,
      		step_g  => 1
    	)
    	port map (
      		clk             => clk,
      		rst_n           => rst_n,
      		sync_clear_n_in => keys_in(0),
      		value_out       => wave_out_bus((1*data_width_g)-1 downto (0*data_width_g))
    	);

  	wave_gen_1 : wave_gen
    	generic map (
      		width_g => data_width_g,
      		step_g  => 2
    	)
    	port map (
      		clk             => clk,
      		rst_n           => rst_n,
      		sync_clear_n_in => keys_in(1),
      		value_out       => wave_out_bus((2*data_width_g)-1 downto (1*data_width_g))
    	);

  	wave_gen_2 : wave_gen
    	generic map (
      		width_g => data_width_g,
      		step_g  => 4
    	)
    	port map (
      		clk             => clk,
      		rst_n           => rst_n,
      		sync_clear_n_in => keys_in(2),
      		value_out       => wave_out_bus((3*data_width_g)-1 downto (2*data_width_g))
    	);

  	wave_gen_3 : wave_gen
    	generic map (
      		width_g => data_width_g,
      		step_g  => 8
    	)
   		port map (
      		clk             => clk,
      		rst_n           => rst_n,
      		sync_clear_n_in => keys_in(3),
      		value_out       => wave_out_bus((4*data_width_g)-1 downto (3*data_width_g))
    	);

---Instantiate multiport adder

	multi_port_adder_0 : multi_port_adder
    	generic map (
      		operand_width_g   => data_width_g,
      		num_of_operands_g => n_keys_g
    	)
    	port map (
      		clk         => clk,
      		rst_n       => rst_n,
      		operands_in => wave_out_bus,
      		sum_out     => sum_out_bus
    	);

----Instantiate audio_ctrl

	audio_ctrl_0 : audio_ctrl
    	generic map (
      		ref_clk_freq_g => clk_freq_g,
      		sample_rate_g  => sample_rate_g,
      		data_width_g   => data_width_g
    	)
    	port map (
      		clk           => clk,
      		rst_n         => rst_n,
      		left_data_in  => sum_out_bus,
      		right_data_in => sum_out_bus,
      		aud_bclk_out  => aud_bclk_out,
      		aud_lrclk_out => aud_lrclk_out,
      		aud_data_out  => aud_data_out
    	);

end structural;

