-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise B02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : sine_wave_gen.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 07.11.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sine wave generator
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY wave_gen IS
	GENERIC (
		width_g : INTEGER := 16;  
		step_g  : INTEGER := 64  
	);
	PORT (
		clk              : IN  STD_LOGIC;                             
		rst_n            : IN  STD_LOGIC;                             
		sync_clear_n_in  : IN  STD_LOGIC;                             
		value_out         : OUT STD_LOGIC_VECTOR(width_g-1 DOWNTO 0)   
	);
END wave_gen;


ARCHITECTURE behavioral OF wave_gen IS
	
	-- Main waveform control signals
	SIGNAL counter   : SIGNED(width_g-1 DOWNTO 0) := (OTHERS => '0'); -- Phase counter
	SIGNAL direction : STD_LOGIC := '1';                              -- Ramp direction (1=up, 0=down)

	-- Intermediate signals for shaping
	SIGNAL tri_val   : SIGNED(width_g-1 DOWNTO 0);  -- Triangular waveform
	SIGNAL abs_val   : SIGNED(width_g-1 DOWNTO 0);  -- Absolute value of tri_val
	SIGNAL sine_like : SIGNED(width_g-1 DOWNTO 0);  -- Sine-like output waveform

	-- Limit constants defining range of the counter
	CONSTANT min_c : SIGNED(width_g-1 DOWNTO 0) := 
		to_signed((-2**(width_g-1)) + ((2**(width_g-1)) MOD step_g), width_g);

	CONSTANT max_c : SIGNED(width_g-1 DOWNTO 0) := 
		to_signed(((2**(width_g-1)-1) - ((2**(width_g-1)-1) MOD step_g)), width_g);
				
BEGIN

	-------------------------------------------------------------------------------
	-- 1. Triangular Wave Generation Process
	--    - Produces a linear up/down ramp signal (counter)
	--    - The direction flips when reaching max or min limits
	--    - Step size (step_g) defines the frequency of the waveform
	-------------------------------------------------------------------------------
	wave_gen_process : PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rst_n = '0' THEN
				counter   <= (OTHERS => '0');
				direction <= '1';

			ELSIF sync_clear_n_in = '0' THEN
				counter   <= (OTHERS => '0');
				direction <= '1';

			ELSE
				IF direction = '1' THEN -- Counting up
					IF counter >= max_c THEN
						direction <= '0'; -- Reverse direction at max
						counter   <= counter - to_signed(step_g, width_g);
					ELSE
						counter   <= counter + to_signed(step_g, width_g);
					END IF;

				ELSE -- Counting down
					IF counter <= min_c THEN
						direction <= '1'; -- Reverse direction at min
						counter   <= counter + to_signed(step_g, width_g);
					ELSE
						counter   <= counter - to_signed(step_g, width_g);
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS wave_gen_process;

	-- Assign triangular waveform
	tri_val <= counter;

	-------------------------------------------------------------------------------
	-- 2. Sine-Like Shaping Logic
	--    - Approximates a sine curve using a polynomial expression:
	--         sine ≈ x * (max - |x|) >> scaling
	--    - This method avoids real numbers and lookup tables.
	--    - Scaling ensures the output fits within the desired amplitude.
	-------------------------------------------------------------------------------
	abs_val   <= (OTHERS => '0') WHEN tri_val(width_g-1) = '0' ELSE -tri_val;
	sine_like <= RESIZE(tri_val * (max_c - abs_val), width_g) SRL (width_g - 5);

	-- Output final sine-like waveform
	value_out <= STD_LOGIC_VECTOR(sine_like);

END behavioral;
