-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 04
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 19.9.2025
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Multi port adder
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;


ENTITY multi_port_adder IS
  GENERIC (
    operand_width_g : INTEGER := 16;
    num_of_operands_g : INTEGER := 4
  );
  PORT (
    clk     : IN  STD_LOGIC;
    rst_n   : IN  STD_LOGIC;
    operands_in : IN STD_LOGIC_VECTOR ((operand_width_g*num_of_operands_g)-1 DOWNTO 0);
    sum_out : OUT STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0)
  );

END multi_port_adder;

ARCHITECTURE structural OF multi_port_adder IS

  COMPONENT adder

	GENERIC (
    		operand_width_g : INTEGER := 16 
  	);
	PORT (
    		a_in	: IN  STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0); 
		b_in    : IN  STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
    		sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0);
		clk     : IN  STD_LOGIC;
    		rst_n   : IN  STD_LOGIC
	);
  END COMPONENT;


  TYPE subtotal_array IS ARRAY (0 to num_of_operands_g/2-1 ) of STD_LOGIC_VECTOR(operand_width_g DOWNTO 0);

  SIGNAL subtotal : subtotal_array;

  SIGNAL total : STD_LOGIC_VECTOR(operand_width_g +1 DOWNTO 0);

BEGIN  

	--adder0
   adder0 : adder

     GENERIC MAP(
        operand_width_g => operand_width_g
     )
     PORT MAP (
	
	clk => clk,
	rst_n => rst_n,
	a_in => operands_in((operand_width_g*4)-1 DOWNTO (operand_width_g*3)),  --63 downto 48
	b_in => operands_in((operand_width_g*3)-1 DOWNTO (operand_width_g*2)),  --47 downto 32
	sum_out => subtotal(0)
     );

	--adder1
   adder1 : adder

     GENERIC MAP(
        operand_width_g => operand_width_g
     )
     PORT MAP (
	
	clk => clk,
	rst_n => rst_n,
	a_in => operands_in((operand_width_g*2)-1 DOWNTO (operand_width_g*1)),  --31 downto 16
	b_in => operands_in((operand_width_g*1)-1 DOWNTO (operand_width_g*0)),  --15 downto 0
	sum_out => subtotal(1)
     );

	--adder2
   adder2 : adder

     GENERIC MAP(
        operand_width_g => operand_width_g+1
     )
     PORT MAP (
	
	clk => clk,
	rst_n => rst_n,
	a_in => subtotal(0),
	b_in => subtotal(1),
	sum_out => total
     );

   sum_out <= total(operand_width_g -1 DOWNTO 0);

--assertion
  ASSERT num_of_operands_g = 4
	--REPORT “only 4 operands supported"
    SEVERITY FAILURE;
    
END structural;



