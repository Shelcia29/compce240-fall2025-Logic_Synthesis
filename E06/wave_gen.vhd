-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 06
-- Project    : 
-------------------------------------------------------------------------------
-- File       : wave_gen.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 03.10.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Triangular wave generator
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
    		width_g : INTEGER := 4;
    		step_g : INTEGER := 2
  	);
  
	PORT (
    		clk     : IN  STD_LOGIC;
    		rst_n   : IN  STD_LOGIC;
    		sync_clear_n_in : IN STD_LOGIC;
    		value_out : OUT STD_LOGIC_VECTOR(width_g-1 DOWNTO 0) 
  	);

END wave_gen;

ARCHITECTURE behavioral OF wave_gen IS
  	
	SIGNAL counter    : SIGNED(width_g-1 DOWNTO 0) := (OTHERS => '0');
  	SIGNAL direction  : STD_LOGIC := '1';


	CONSTANT min_c  : SIGNED(width_g-1 DOWNTO 0) := 
		--to_signed(-(2**(width_g-1)) + step_g, width_g);
		to_signed((-2**(width_g-1)) + ((2**(width_g-1)) mod step_g), width_g);

	CONSTANT max_c  : SIGNED(width_g-1 DOWNTO 0) := 
		--to_signed((2**(width_g-1) - 1) - step_g, width_g);
		to_signed(((2**(width_g-1)-1) - ((2**(width_g-1)-1) mod step_g)), width_g);
				

BEGIN

 	wave_gen_process : PROCESS(clk)

  		BEGIN
    			IF rising_edge(clk) THEN
      				IF rst_n = '0' THEN
        				counter   <= (OTHERS => '0');
					--counter <= to_signed(step_g);
        				direction <= '1';

      				ELSIF sync_clear_n_in = '0' THEN
        				counter   <= (OTHERS => '0');
        				direction <= '1';

      				ELSE
        				IF direction = '1' THEN -- counting up
          					IF counter = max_c THEN
            						direction <= '0';
            						counter   <= counter - to_signed(step_g, width_g);
          					ELSE
            						counter <= counter + to_signed(step_g, width_g);
          					END IF;

        				ELSE -- counting down
          					IF counter <= min_c THEN
            						direction <= '1';
            						counter   <= counter + to_signed(step_g, width_g);
          					ELSE
            						counter <= counter - to_signed(step_g, width_g);
          					END IF;
        				END IF;
      				END IF;
    			END IF;
	END PROCESS wave_gen_process;

value_out <= std_logic_vector(counter);

END behavioral;

