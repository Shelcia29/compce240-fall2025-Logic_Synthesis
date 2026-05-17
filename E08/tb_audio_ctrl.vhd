-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 08
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_audio_ctrl.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 04.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Audio Ctrl Testbench
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_ctrl is
end tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is

--constants

  constant clk_period_c   : time := 50 ns;        
  constant ref_clk_freq_c : integer := 20000000;  
  constant sample_rate_c  : integer := 48000;
  constant data_width_c   : integer := 16;

--signals

  signal clk            : std_logic := '0';
  signal rst_n          : std_logic := '0';
  signal sync_clear_n   : std_logic := '1';  

  signal left_data_in   : std_logic_vector(data_width_c-1 downto 0):= (others=>'0');
  signal right_data_in  : std_logic_vector(data_width_c-1 downto 0):= (others=>'1');

  signal aud_bclk_out   : std_logic;
  signal aud_lrclk_out  : std_logic;
  signal aud_data_out   : std_logic;

  signal value_left_out: std_logic_vector(data_width_c-1 downto 0);
  signal value_right_out: std_logic_vector(data_width_c-1 downto 0);

-- component declarations 
-- declare wave generator, audio controller, audio codec model

  component wave_gen
    generic (
      width_g : integer := 4;
      step_g  : integer := 2
    );
    port (
      clk              : in  std_logic;
      rst_n            : in  std_logic;
      sync_clear_n_in  : in  std_logic;
      value_out        : out std_logic_vector(width_g-1 downto 0)
    );
  end component;

  component audio_ctrl
    generic (
      ref_clk_freq_g : integer := 12288000;
      sample_rate_g  : integer := 48000;
      data_width_g   : integer := 16
    );
    port (
      clk           : in  std_logic;
      rst_n         : in  std_logic;
      left_data_in  : in  std_logic_vector(data_width_g-1 downto 0);
      right_data_in : in  std_logic_vector(data_width_g-1 downto 0);
      aud_bclk_out  : out std_logic;
      aud_lrclk_out : out std_logic;
      aud_data_out  : out std_logic
    );
  end component;

  component audio_codec_model
    generic (
      data_width_g : integer := 16
    );
    port (
      rst_n           : in  std_logic;
      aud_data_in     : in  std_logic;
      aud_bclk_in     : in  std_logic;
      aud_lrclk_in    : in  std_logic;
      value_left_out  : out std_logic_vector(data_width_g-1 downto 0);
      value_right_out : out std_logic_vector(data_width_g-1 downto 0)
    );
  end component;

begin

----- generating clock

  clk <= not clk after clk_period_c/2;

----- reset sequence

  reset_process : process
  begin
    rst_n <= '0';
    wait for 200 ns;      
    rst_n <= '1';
    wait;
  end process reset_process;

----- sync_clear process

  sync_clear_process : process
  begin

    sync_clear_n <= '1';
      wait for 50 ns;
    sync_clear_n <= '0';
      wait for 200 ns;
    sync_clear_n <= '1';

    wait;
  end process sync_clear_process;

----------------Instantiation-------------------------
--Two wave gens
--Audio codec
--Audio control

  -- Instantiate two wave_gens 
  -- left : step size 2 and right : step size 10 

  -- left wave gen

  wave_gen_left : wave_gen
    generic map (
      width_g => data_width_c,
      step_g  => 2
    )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,
      value_out       => left_data_in
    );

  -- right wave gen

  wave_gen_right : wave_gen
    generic map (
      width_g => data_width_c,
      step_g  => 10
    )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,
      value_out       => right_data_in
    );

  -- Instantiate audio_ctrl

  audio_ctrl_0 : audio_ctrl
    generic map (
      ref_clk_freq_g => ref_clk_freq_c, 
      sample_rate_g  => sample_rate_c,
      data_width_g   => data_width_c
    )
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => left_data_in,
      right_data_in => right_data_in,
      aud_bclk_out  => aud_bclk_out,
      aud_lrclk_out => aud_lrclk_out,
      aud_data_out  => aud_data_out
    );

  -- Instantiate audio codec model

  audio_codec_model_0 : audio_codec_model
    generic map (
      data_width_g => data_width_c
    )
    port map (
      rst_n           => rst_n,
      aud_data_in     => aud_data_out,
      aud_bclk_in     => aud_bclk_out,
      aud_lrclk_in    => aud_lrclk_out,
      value_left_out  => value_left_out,
      value_right_out => value_right_out
    );

end testbench;

