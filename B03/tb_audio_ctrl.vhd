-- -------------------------------------------------------------------------------
-- -- Title      : COMP.CE.240, Exercise B03
-- -- Project    : 
-- -------------------------------------------------------------------------------
-- -- File       : tb_audio_ctrl_self_check.vhd
-- -- Author     : Ashinsani, Shelcia
-- -- Company    : TAU
-- -- Edited     : 09.11.2025
-- -- Platform   : 
-- -- Standard   : VHDL'87
-- -------------------------------------------------------------------------------
-- -- Description: Audio Ctrl Testbench with self check
-- -------------------------------------------------------------------------------
-- -- Copyright (c) 2025 
-- -------------------------------------------------------------------------------
-- -- Revisions  :
-- -- Date        Version  Author  Description

-- -------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_ctrl is
end tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is

  ---------------------------------------------------------------------------
  -- Helper function: convert std_logic_vector to hex string (for reports)
  ---------------------------------------------------------------------------
  function to_hstring(v : std_logic_vector) return string is
    variable result : string(1 to (v'length + 3) / 4);
    variable temp   : std_logic_vector(3 downto 0);
    variable idx    : integer := 1;
  begin
    for i in v'length-1 downto 0 loop
      temp(3 - (i mod 4)) := v(i);
      if (i mod 4 = 0) or (i = 0) then
        case temp is
          when "0000" => result(idx) := '0';
          when "0001" => result(idx) := '1';
          when "0010" => result(idx) := '2';
          when "0011" => result(idx) := '3';
          when "0100" => result(idx) := '4';
          when "0101" => result(idx) := '5';
          when "0110" => result(idx) := '6';
          when "0111" => result(idx) := '7';
          when "1000" => result(idx) := '8';
          when "1001" => result(idx) := '9';
          when "1010" => result(idx) := 'A';
          when "1011" => result(idx) := 'B';
          when "1100" => result(idx) := 'C';
          when "1101" => result(idx) := 'D';
          when "1110" => result(idx) := 'E';
          when "1111" => result(idx) := 'F';
          when others => result(idx) := 'X';
        end case;
        idx := idx + 1;
      end if;
    end loop;
    return result;
  end function to_hstring;

  ---------------------------------------------------------------------------
  -- Simulation constants
  ---------------------------------------------------------------------------
  constant clk_period_c   : time := 50 ns;         -- 20 MHz
  constant ref_clk_freq_c : integer := 20000000;
  constant sample_rate_c  : integer := 48000;
  constant data_width_c   : integer := 16;

  -- Signals
  signal clk            : std_logic := '0';
  signal rst_n          : std_logic := '0';
  signal sync_clear_n   : std_logic := '1';

  signal left_data_in   : std_logic_vector(data_width_c-1 downto 0):= (others=>'0');
  signal right_data_in  : std_logic_vector(data_width_c-1 downto 0):= (others=>'1');

  signal aud_bclk_out   : std_logic;
  signal aud_lrclk_out  : std_logic;
  signal aud_data_out   : std_logic;

  signal value_left_out  : std_logic_vector(data_width_c-1 downto 0);
  signal value_right_out : std_logic_vector(data_width_c-1 downto 0);

  signal expected_left   : std_logic_vector(data_width_c-1 downto 0) := (others=>'0');
  signal expected_right  : std_logic_vector(data_width_c-1 downto 0) := (others=>'0');

  signal prev_lrclk      : std_logic := '0';
  signal prev_val_left   : std_logic_vector(data_width_c-1 downto 0) := (others=>'0');
  signal prev_val_right  : std_logic_vector(data_width_c-1 downto 0) := (others=>'0');

  signal error_count     : integer := 0;
  signal sample_count    : integer := 0;

  ---------------------------------------------------------------------------
  -- Component declarations
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Clock generation
  ---------------------------------------------------------------------------
  clk <= not clk after clk_period_c/2;

  ---------------------------------------------------------------------------
  -- Reset & sync_clear sequences
  ---------------------------------------------------------------------------
  reset_process : process
  begin
    rst_n <= '0';
    wait for 200 ns;
    rst_n <= '1';
    wait;
  end process;

  sync_clear_process : process
  begin
    sync_clear_n <= '1';
    wait for 50 ns;
    sync_clear_n <= '0';
    wait for 200 ns;
    sync_clear_n <= '1';
    wait;
  end process;

  ---------------------------------------------------------------------------
  -- Instantiate wave generators
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Instantiate DUT: audio_ctrl
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Instantiate simulated codec model
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Self-checking logic
  ---------------------------------------------------------------------------
  self_check_proc : process(clk)
  begin
    if rising_edge(clk) then

      -- Detect frame start (falling edge of LRCLK)
      if (prev_lrclk = '1' and aud_lrclk_out = '0') then
        expected_left  <= left_data_in;
        expected_right <= right_data_in;
        sample_count   <= sample_count + 1;
      end if;

      prev_lrclk <= aud_lrclk_out;

      -- Compare Left Channel
      if (value_left_out /= prev_val_left) then
        if (value_left_out /= expected_left) then
          report "ERROR @ frame " & integer'image(sample_count)
                 & " Left mismatch: expected " & to_hstring(expected_left)
                 & " got " & to_hstring(value_left_out)
                 severity error;
          error_count <= error_count + 1;
        else
          report "OK    @ frame " & integer'image(sample_count)
                 & " Left matched: " & to_hstring(value_left_out)
                 severity note;
        end if;
        prev_val_left <= value_left_out;
      end if;

      -- Compare Right Channel
      if (value_right_out /= prev_val_right) then
        if (value_right_out /= expected_right) then
          report "ERROR @ frame " & integer'image(sample_count)
                 & " Right mismatch: expected " & to_hstring(expected_right)
                 & " got " & to_hstring(value_right_out)
                 severity error;
          error_count <= error_count + 1;
        else
          report "OK    @ frame " & integer'image(sample_count)
                 & " Right matched: " & to_hstring(value_right_out)
                 severity note;
        end if;
        prev_val_right <= value_right_out;
      end if;

    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Simulation end and summary
  ---------------------------------------------------------------------------
  end_sim_proc : process
  begin
    wait for 40 ms;
    if error_count = 0 then
      report "TEST PASSED. Frames checked: " & integer'image(sample_count) severity note;
    else
      report "TEST FAILED. Frames checked: " & integer'image(sample_count)
             & " Errors: " & integer'image(error_count) severity error;
    end if;
    wait;
  end process;

end architecture testbench;


