-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 11.9.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Generic adder
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


ENTITY adder IS
  GENERIC (
    operand_width_g : INTEGER  
  );
  PORT (
    clk     : IN  STD_LOGIC;
    rst_n   : IN  STD_LOGIC;
    a_in    : IN  STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
    b_in    : IN  STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
    sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0)
  );
END adder;


ARCHITECTURE rt1 OF adder IS

	SIGNAL result : SIGNED(operand_width_g DOWNTO 0);

BEGIN  

  sum_out <= STD_LOGIC_VECTOR(result);

  PROCESS(clk, rst_n)
  BEGIN
    IF rst_n = '0' THEN
      result <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
	result <= resize(SIGNED(a_in),operand_width_g + 1) + resize(SIGNED(b_in),operand_width_g + 1);
    END IF;
  END PROCESS; 
    
END rt1;

