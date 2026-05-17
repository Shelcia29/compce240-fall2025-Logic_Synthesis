-- TODO: Add VHDL Header here (in Emacs use: VHDL->Template->Insert Header )
--       Use your group number and name(s) of the group member(s)
--       in the 'author' field
--       Testbench has an example what a good header should look like

-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 8.9.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Ripple carry adder
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------


-- TODO: Add library called ieee here
--       And use package called std_logic_1164 from the library

library ieee;
use ieee.std_logic_1164.all;


-- TODO: Declare entity here
-- Name: ripple_carry_adder
-- No generics yet
-- Ports: a_in  3-bit std_logic_vector
--        b_in  3-bit std_logic_vector
--        s_out 4-bit std_logic_vector

ENTITY ripple_carry_adder IS

   PORT (
      a_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
      b_in    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_out   : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0)
      );
      

END ripple_carry_adder;

-------------------------------------------------------------------------------

-- Architecture called 'gate' is already defined. Just fill it.
-- Architecture defines an implementation for an entity
architecture gate of ripple_carry_adder is

  -- TODO: Add your internal signal declarations here
	
	signal carry_ha : STD_LOGIC;
	signal carry_fa : STD_LOGIC;

  
begin  -- gate

  -- TODO: Add signal assignments here
  -- x(0) <= y and z(2);
  -- Remember that VHDL signal assignments happen in parallel
  -- Don't use processes

    
    s_out(0) <= a_in(0) xor b_in(0);
    carry_ha <= a_in(0) and b_in(0);

    
    s_out(1) <= (a_in(1) xor b_in(1)) xor carry_ha;
    carry_fa <= ((a_in(1) xor b_in(1)) and carry_ha) or (a_in(1) and b_in(1));

    
    s_out(2) <= (a_in(2) xor b_in(2)) xor carry_fa;

    
    s_out(3) <= ((a_in(2) xor b_in(2)) and carry_fa) or (a_in(2) and b_in(2));
    
end gate;
