-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 08
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 29.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Audio codec controller
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ctrl is
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
    aud_data_out  : out std_logic;  
    aud_lrclk_out : out std_logic   
  );
end audio_ctrl;

architecture behavioral of audio_ctrl is

  -----signals
  -- signal left_reg_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  -- signal right_reg_r : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  -- signal sample_count : integer := 0;
  signal data_r  : std_logic_vector((2 * data_width_g) - 1 downto 0);  
  signal bclk_cnt : integer := 0; 
  signal lrclk_cnt : integer := 0;  
  signal aud_out_r            : std_logic := '0';

  signal aud_bclk_out_r : std_logic := '0';  
  signal aud_lrclk_out_r      : std_logic := '0';  
  signal sel_cntr_r        : integer := 0; 

  ------constants
  constant value_bclk_c : integer := ref_clk_freq_g / (sample_rate_g * data_width_g * 2 * 2);
 -- constant value_lrclk_c  : integer := (ref_clk_freq_g / (2 * sample_rate_g));  

  
begin

 --- changed the thress step process into a single process
 --- inorder to fix the lrclk and bclk sync issue
 
  audio_data_out_process : process(clk, rst_n)
  begin
    if rst_n = '0' then
      aud_lrclk_out <= '0';
      aud_lrclk_out_r <= '0';
      aud_bclk_out_r <= '0';
      aud_bclk_out <= '0';
      bclk_cnt <= 0;
      lrclk_cnt <= 0;
      sel_cntr_r <= 0;
      data_r <= (others => '0');
      
    elsif rising_edge(clk) then

    -- bclk increment counter
      bclk_cnt <= bclk_cnt + 1;  

      -- sampling input data before the left channel is output
      if (aud_bclk_out_r = '0' and bclk_cnt = (value_bclk_c - 1) and 
        sel_cntr_r = (data_width_g * 2) - 1) then
        -- concatanate left and right input data
        data_r <= (left_data_in & right_data_in);  
      end if;

      -- flip bclk value when counter reaches max
      if (bclk_cnt = (value_bclk_c - 1)) then
        aud_bclk_out <= aud_bclk_out_r;
        aud_bclk_out_r <= not aud_bclk_out_r;
        
        -- lrclk counter when bclk is falling edge
        if (aud_bclk_out_r = '0') then  
          lrclk_cnt <= lrclk_cnt + 1;
          
          if (lrclk_cnt = (data_width_g - 1)) then
            aud_lrclk_out <= aud_lrclk_out_r;
            aud_lrclk_out_r <= not aud_lrclk_out_r;
            lrclk_cnt <= 0;  
          end if;
        end if;

        bclk_cnt <= 0;  
      end if;

      -- shift data on the falling edge of bclk
      if (aud_bclk_out_r = '0' and bclk_cnt = (value_bclk_c - 1) and 
        sel_cntr_r /= (data_width_g * 2) - 1) then
          data_r <= (data_r((2 * data_width_g) - 2 downto 0) & '0'); 
          sel_cntr_r <= sel_cntr_r + 1;
        
      elsif (bclk_cnt = (value_bclk_c - 1) and aud_bclk_out_r = '0' and sel_cntr_r = 0) then
        sel_cntr_r <= sel_cntr_r + 1;
      end if;

      -- reset selection counter at lrclk high edge
      if (aud_bclk_out_r = '0' and bclk_cnt = (value_bclk_c - 1) and 
        aud_lrclk_out_r = '1' and lrclk_cnt = (data_width_g - 1)) then
          sel_cntr_r <= 0;
      end if;
      
    end if;
  end process audio_data_out_process;

  -- output the audio data (msb of the register)
  aud_data_out <= data_r((2 * data_width_g) - 1);

end architecture behavioral;



