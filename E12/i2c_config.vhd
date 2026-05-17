
-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 12
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 30.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: i2c config
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-------------------------------------------------------------------------------
library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity i2c_config is
  generic(
    ref_clk_freq_g : integer := 50000000;  
    i2c_freq_g     : integer := 20000;  
    n_params_g     : integer := 15;  
    n_leds_g       : integer := 4  
   );

 port(
   clk  : in std_logic;
   rst_n : in std_logic;
   sdat_inout       : inout std_logic;  
   sclk_out         : out  std_logic;  
   param_status_out : out  std_logic_vector(n_leds_g-1 downto 0); 
   finished_out     : out  std_logic  
   );
end i2c_config;

architecture behavior of i2c_config is

  signal sda_en_r       : std_logic;
  signal received_ack_r : std_logic;

  type codec_reg_t is array(0 to n_params_g-1) of std_logic_vector(n_params_g downto 0);

  signal reg : codec_reg_t;
  constant byte_c  : integer  := 7;

  subtype byte is std_logic_vector(7 downto 0);
  constant dev_addr : byte := "00110100";   

  -- Configuration data (register address + data value pairs)

  type reginfo_t is array (0 to 14) of std_logic_vector(n_params_g downto 0);

  constant reg_info_c : reginfo_t := (
    "0001110110000000",  "0010011100000100",  "0010001000001011",  "0010100000000000",  "0010100110000001",  
    "0110100100001000",  "0110101000000000",  "0100011111100001",  "0110101100001001",  "0110110000001000",  
    "0100101100001000",  "0100110000001000",  "0110111010001000",  "0110111110001000",  "0101000111110001"   
);

  -- State machine declaration

  type states_type is (start, address_trx, wait_ack, send_reg_addr, send_data, stop_cond);
  signal state       : states_type; --current state
  signal prev_state      : states_type; --previous state

  signal sdat_r     : std_logic;
  signal sclk_old_r : std_logic;
  signal clk_counter : integer := 0;
  signal sclk_out_sig : std_logic;
  signal bit_counter : integer range 0 to 8;
  signal param_index  : integer;
  signal finished_sig  : std_logic;

  constant sclk_half  : integer := ref_clk_freq_g/(2*i2c_freq_g);

begin

-- Clock Generation Process (SCL)
-- Generates the I2C clock signal at the desired frequency.

  sclk_generation : process(clk, rst_n)

  begin
    if(rst_n = '0') then
      clk_counter <= 0;
      sclk_out_sig  <= '0';
      sclk_old_r  <= '0';

    elsif(clk'event and clk = '1') then
      sclk_old_r <= sclk_out_sig;         
      if(clk_counter = (sclk_half -1)) then  
        sclk_out_sig  <= not(sclk_out_sig);
        clk_counter <= 0;
      else  
        clk_counter <= clk_counter+1;
      end if;
    end if;

  end process sclk_generation;

-- SDA Line Control
-- Controls whether SDA is driven or released (tri-stated)

  with sda_en_r select
    sdat_inout <=  'Z'   when '0', sdat_r when others;
  with finished_sig select  
    sclk_out <= 'Z' when '1', sclk_out_sig when others;

-- Register Initialization
-- Loads the register values from reg_info_c into local register array.

 reg_fill : process(rst_n, clk)
  begin 
    if(rst_n = '0') then

      for i in 0 to n_params_g-1 loop
        reg(i) <= reg_info_c(i);
      end loop;

    elsif(clk'event and clk = '1')then

   end if;

 end process reg_fill;

-- Main State Machine
-- Handles I2C transactions: START → ADDRESS → ACK → REGISTER → DATA → STOP

  fsm : process(rst_n, clk)
  begin
    if(rst_n = '0')then
      received_ack_r   <= '0';
      sda_en_r    <= '1';
      sdat_r    <= '1';
      bit_counter <= 0;
      param_index   <= 0;
      state    <= start;
      prev_state   <= start;
      param_status_out   <= (others => '0');
      finished_sig    <= '0';

   elsif(clk'event and clk = '1') then

     case state is

-----------------------------------------------------------------------
        when start =>  
          sda_en_r <= '1';
          if (sclk_old_r = '1' and sclk_out_sig = '1' and sdat_r = '1' and clk_counter = (sclk_half /2)) then  
            sdat_r          <= '0';
            state <= address_trx;
          else
            sdat_r <= '1';
          end if;
-----------------------------------------------------------------------
        when address_trx =>
          if(sclk_old_r = '1' and sclk_out_sig = '0')then 
            if(bit_counter = 8) then              
              state  <= wait_ack;
              sda_en_r  <= '0';
              prev_state <= address_trx;
            else                      
              sdat_r  <= dev_addr(7-bit_counter);
              bit_counter <= bit_counter+1;
            end if;
         end if;
-----------------------------------------------------------------------
        when wait_ack =>
          bit_counter <= 0;
          if(clk_counter = (sclk_half /2) and sclk_out_sig = '1') then  
            received_ack_r <= sdat_inout;
          end if;
          if(clk_counter = (sclk_half -1) and sclk_out_sig = '1') then 
            if(received_ack_r = '0' and prev_state = address_trx) then 
              state <= send_reg_addr;
            elsif(received_ack_r = '0' and prev_state = send_reg_addr) then  
              state <= send_data;
            elsif(received_ack_r = '0' and prev_state = send_data) then 
              state <= stop_cond;
            elsif(received_ack_r = '1') then  
              state <= start;
            end if;
          end if;
-----------------------------------------------------------------------
       when send_reg_addr =>
          if(sclk_old_r = '1' and sclk_out_sig = '0')then  
            sda_en_r <= '1';
            if(bit_counter = 8) then             
              state  <= wait_ack;
              sda_en_r  <= '0';
              prev_state <= send_reg_addr;
            else                        
              sdat_r   <= reg(param_index)(n_params_g-bit_counter);  
              bit_counter <= bit_counter+1;
            end if;
          end if;
-----------------------------------------------------------------------
       when send_data =>
          if(sclk_old_r = '1' and sclk_out_sig = '0')then  
            sda_en_r <= '1';
            if(bit_counter = 8) then              
              state  <= wait_ack;
              sda_en_r     <= '0';
              prev_state <= send_data;
            else                        
              sdat_r   <= reg(param_index)(byte_c-bit_counter);  
              bit_counter <= bit_counter + 1;
            end if;
         end if;
-----------------------------------------------------------------------
        when stop_cond =>
          sda_en_r <= '1';

         if (sclk_old_r = '1' and sclk_out_sig = '1' and sdat_r = '0' and clk_counter = (sclk_half /2))then  
            sdat_r <= '1';
            if(param_index = (n_params_g-1)) then  
              finished_sig   <= '1'; 
              param_status_out <= std_logic_vector(to_unsigned(param_index, n_leds_g)+1);
            else
              state  <= start;
              param_index  <= param_index + 1;
              param_status_out <= std_logic_vector(to_unsigned(param_index, n_leds_g)+1);
            end if;
          else
            sdat_r <= '0';
          end if;
      end case;
    end if;
  end process fsm;

-- Output Assignment

 finished_out <= finished_sig;

end architecture behavior;