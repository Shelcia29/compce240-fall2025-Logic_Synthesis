-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 08
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 29.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Audio codec model
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_codec_model is
  generic(
    data_width_g : integer := 16 
  );
  port(
    rst_n        : in std_logic;
    aud_data_in  : in std_logic;
    aud_bclk_in  : in std_logic;
    aud_lrclk_in : in std_logic;

    value_left_out  : out std_logic_vector(data_width_g-1 downto 0);
    value_right_out : out std_logic_vector(data_width_g-1 downto 0)
  );
end audio_codec_model;

architecture behavioral of audio_codec_model is

  -- defining FSM states
  type state_types is (wait_for_input, read_left, read_right);
  signal present_state      : state_types := wait_for_input;

  -- internal registers and counters

  signal aud_data_r       : std_logic := '0';              
  signal leftright_data_r  : std_logic_vector(data_width_g-1 downto 0) := (others => '0');  
  signal bit_count    : integer range 1 to data_width_g := 1;    

begin

  process_audio_codec : process(aud_bclk_in, rst_n)

  begin
    if rst_n = '0' then
 
      present_state <= wait_for_input;
      leftright_data_r <= (others => '0');
      aud_data_r      <= '0';
      value_left_out  <= (others => '0');
      value_right_out <= (others => '0');
      bit_count   <= 1;
      
    elsif rising_edge(aud_bclk_in) then

      -- on rising edge of bclk, store the incoming data
      aud_data_r <= aud_data_in;

      if (present_state = read_left or present_state = read_right) then     
        if bit_count < data_width_g then
          leftright_data_r(data_width_g - bit_count) <= aud_data_r;
          bit_count <= bit_count + 1;
        end if;
      end if;

      -- State transitions based on lrclk signal
      if present_state = read_left and aud_lrclk_in = '0' then
        present_state <= read_right;
        value_left_out  <= leftright_data_r;
        bit_count   <= 1;
        
      elsif (present_state = read_right or present_state = wait_for_input) and aud_lrclk_in = '1' then
        present_state <= read_left;
        value_right_out <= leftright_data_r;
        bit_count   <= 1;
      end if;
    end if;

  end process process_audio_codec;

end architecture behavioral;

