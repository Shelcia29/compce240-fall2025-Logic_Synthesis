-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 12
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_i2c_config.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 27.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Testbench i2c config
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Empty entity
-------------------------------------------------------------------------------

entity tb_i2c_config is
end tb_i2c_config;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------

architecture testbench of tb_i2c_config is

  -- Number of parameters to expect

  constant n_params_c     : integer := 15;
  constant n_leds_c       : integer := 4;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits.

  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;

  type reginfo_t is array (0 to n_params_c-1) of std_logic_vector (bit_count_max_c-1 downto 0);

  constant addresses_c : reginfo_t := (
    "00011101", "00100111", "00100010", "00101000", "00101001",
    "01101001", "01101010", "01000111", "01101011", "01101100",
    "01001011", "01001100", "01101110", "01101111", "01010001"
  );

  constant values_c : reginfo_t := (
    "10000000", "00000100", "00001011", "00000000", "10000001",
    "00001000", "00000000", "11100001", "00001001", "00001000",
    "00001000", "00001000", "10001000", "10001000", "11110001"
  );
                     

  constant device_address : std_logic_vector (7 downto 0)  :=  ("00110100");

  -- Signals fed to the DUV
  signal clk   : std_logic := '0';  -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis


  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer;
      n_leds_g       : integer);
    port (
      clk              : in    std_logic;
      rst_n            : in    std_logic;
      sdat_inout       : inout std_logic;
      sclk_out         : out   std_logic;
      param_status_out : out   std_logic_vector(n_leds_g-1 downto 0);
      finished_out     : out   std_logic
      );

  end component;

  -- Signals coming from the DUV
  signal sdat         : std_logic := 'Z';
  signal sclk         : std_logic;
  signal param_status : std_logic_vector(n_leds_c-1 downto 0);
  signal finished     : std_logic;

  -- To hold the value that will be driven to sdat when sclk is high.
  signal sdat_r : std_logic;

  -- Counters for receiving bits and bytes
  signal bit_counter_r    : integer range 0 to bit_count_max_c;
  signal byte_counter_r   : integer range 0 to n_bytes_c-1; -- 2:0

  signal nack1_cnt_r      : integer range 1 downto 0;
  signal nack2_cnt_r      : integer range 1 downto 0;

  signal reg_cnt_r        : integer range n_params_c-1 downto 0; -- 14:0  

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop);
  signal curr_state_r : states;
 
  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;

  type   reg_arrays is array (0 to n_bytes_c-1) of std_logic_vector (n_params_c-1 downto 0); 
  signal ref_r : reg_arrays;

  signal dut_received_r : std_logic_vector(bit_count_max_c-1 downto 0);

begin  -- testbench

  clk   <= not clk after clock_period_c/2;
  rst_n <= '1'     after clock_period_c*4;

  -- Assign sdat_r when sclk is active, otherwise 'Z'.
  -- Note that sdat_r is usually 'Z'

  with sclk select
    sdat <=
    sdat_r when '1',
    'Z'    when others;

  -- Component instantiation
  i2c_config_1 : i2c_config
     generic map (
      ref_clk_freq_g => ref_freq_c,
      i2c_freq_g     => i2c_freq_c,
      n_params_g     => n_params_c,
      n_leds_g       => n_leds_c)
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sdat,
      sclk_out         => sclk,
      param_status_out => param_status,
      finished_out     => finished);

  -----------------------------------------------------------------------------

  -- The main process that controls the behavior of the test bench

  fsm_proc : process (clk, rst_n)
  begin  -- process fsm_proc
    if rst_n = '0' then                 -- asynchronous reset (active low)

      curr_state_r <= wait_start; 

      sdat_old_r <= '0';
      sclk_old_r <= '0';

      byte_counter_r <= 0;
      bit_counter_r  <= 0;

      sdat_r <= 'Z';

      reg_cnt_r      <= 0;
      
      nack1_cnt_r     <= 0;
      nack2_cnt_r    <= 0;

      ref_r(0)   <= (others => '0'); 
      ref_r(1)   <= (others => '0'); 
      ref_r(2)   <= (others => '0'); 
      dut_received_r   <= (others => '0');

      

    elsif clk'event and clk = '1' then  -- rising clock edge

      -- The previous values are required for the edge detection
      sclk_old_r <= sclk;
      sdat_old_r <= sdat;

      -- Falling edge detection for acknowledge control
      -- Must be done on the falling edge in order to be stable during
      -- the high period of sclk

      if sclk = '0' and sclk_old_r = '1' then

        -- If we are supposed to send ack
        if curr_state_r = read_byte and bit_counter_r = bit_count_max_c then

          -- Send ack (low = ACK)
          if reg_cnt_r = 1 and byte_counter_r = 2 and nack1_cnt_r = 0 then
            sdat_r         <= '1';
            nack1_cnt_r <= nack1_cnt_r + 1;
          else
            sdat_r <= '0';
          end if;
        else

          -- Otherwise, sdat is in high impedance state.
          sdat_r <= 'Z';

        end if;  

      end if;
      -------------------------------------------------------------------------
      -- FSM
      case curr_state_r is
        -----------------------------------------------------------------------
        -- Wait for the start condition
        when wait_start =>

          -- While clk stays high, the sdat falls
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '1' and sdat = '0' then

            curr_state_r <= read_byte;

          end if;

          --------------------------------------------------------------------
          -- Wait for a byte to be read
        when read_byte =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then

            if bit_counter_r /= bit_count_max_c then

              -- Normally just receive a bit
              bit_counter_r  <= bit_counter_r + 1;

              dut_received_r(bit_count_max_c - bit_counter_r - 1) <= sdat;

            else
              -- When terminal count is reached, let's send the ack
              curr_state_r  <= send_ack;
              bit_counter_r <= 0;

              dut_received_r <=  (others => '0');

            end if;  -- Bit counter terminal count
         
          elsif sclk = '0' and sclk_old_r = '1' and bit_counter_r = 0 then
            dut_received_r(0) <= sdat;

          end if;  -- sclk rising clock edge
          --------------------------------------------------------------------
          -- Send acknowledge
        when send_ack =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then 

            if byte_counter_r /= n_bytes_c-1 then

              -- Transmission continues
              if reg_cnt_r = 1 and byte_counter_r = 2 and nack2_cnt_r = 0 then

                byte_counter_r   <= 0;
                curr_state_r     <= wait_stop;
                nack2_cnt_r <= nack2_cnt_r + 1;

              else

              bit_counter_r  <= bit_counter_r + 1;
              byte_counter_r <= byte_counter_r + 1;
              curr_state_r   <= read_byte;

              end if;
            else

              -- Transmission is about to stop
              byte_counter_r <= 0;
              curr_state_r   <= wait_stop;
             
              if reg_cnt_r = 1 and byte_counter_r = 2 and nack2_cnt_r = 0 then
                nack2_cnt_r <= nack2_cnt_r + 1;
              elsif reg_cnt_r /= n_params_c-1 then
                reg_cnt_r <= reg_cnt_r + 1;                                                      
              end if;

            end if;
          end if;
          ---------------------------------------------------------------------
          -- Wait for the stop condition

        when wait_stop =>

          -- Stop condition detection: sdat rises while sclk stays high
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '0' and sdat = '1' then

            curr_state_r <= wait_start;

            elsif sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '1' and sdat = '0' then
            curr_state_r <= read_byte;

          end if;

      end case;

    end if;

  end process fsm_proc;

   -----------------------------------------------------------------------------
  -- Asserts for verification
  -----------------------------------------------------------------------------

  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;

  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
    "Simulation done" severity failure;

    --Verify correct device address
  process(clk)
  begin
    if rising_edge(clk) then
      if bit_counter_r = bit_count_max_c and byte_counter_r = 0 then
        assert dut_received_r = device_address
          report "Incorrect I2C device address" severity error;
      end if;
    end if;
  end process;

  -- Verify correct register address
  process(clk)
  begin
    if rising_edge(clk) then
      if bit_counter_r = bit_count_max_c and byte_counter_r = 1 then
        assert dut_received_r = addresses_c(reg_cnt_r)
          report "Incorrect register address" severity error;
      end if;
    end if;
  end process;

  -- Verify R/W bit = 0 (write)
  process(clk)
  begin
    if rising_edge(clk) then
      if bit_counter_r = bit_count_max_c and byte_counter_r = 0 then
        assert dut_received_r(0) = '0'
          report "R/W bit incorrect (expected write=0)" severity error;
      end if;
    end if;
  end process;

  -- Simulation stop condition
  sim_stop_proc : process
  begin
    wait until finished = '1';
    report "All configuration parameters sent successfully."
      severity note;
    wait for 100 ns;
    assert false
      report "Simulation stopped."
      severity note;
  end process;


end testbench;