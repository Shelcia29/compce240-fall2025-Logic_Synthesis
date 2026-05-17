-- -------------------------------------------------------------------------------
-- -- Title      : COMP.CE.240, Exercise B01
-- -- Project    : 
-- -------------------------------------------------------------------------------
-- -- File       : generic_multi_port_adder.vhd
-- -- Author     : Ashinsani, Shelcia
-- -- Company    : TAU
-- -- Edited     : 07.11.2025
-- -- Platform   : 
-- -- Standard   : VHDL'87
-- -------------------------------------------------------------------------------
-- -- Description: Generic Multi port adder
-- -------------------------------------------------------------------------------
-- -- Copyright (c) 2025 
-- -------------------------------------------------------------------------------
-- -- Revisions  :
-- -- Date        Version  Author  Description

-- -------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;  -- Required for unsigned operations

ENTITY multi_port_adder IS
  GENERIC (
    operand_width_g   : INTEGER := 16;
    num_of_operands_g : INTEGER := 4  -- must be 2^n
  );
  PORT (
    clk        : IN  STD_LOGIC;
    rst_n      : IN  STD_LOGIC;
    operands_in: IN  STD_LOGIC_VECTOR((operand_width_g * num_of_operands_g) - 1 DOWNTO 0);
    sum_out    : OUT STD_LOGIC_VECTOR(operand_width_g - 1 DOWNTO 0)
  );
END multi_port_adder;

ARCHITECTURE structural OF multi_port_adder IS

  --------------------------------------------------------------------
  -- Component declaration
  --------------------------------------------------------------------
  COMPONENT adder
    GENERIC (
      operand_width_g : INTEGER := 16
    );
    PORT (
      a_in    : IN  STD_LOGIC_VECTOR(operand_width_g - 1 DOWNTO 0);
      b_in    : IN  STD_LOGIC_VECTOR(operand_width_g - 1 DOWNTO 0);
      sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0);
      clk     : IN  STD_LOGIC;
      rst_n   : IN  STD_LOGIC
    );
  END COMPONENT;

  --------------------------------------------------------------------
  -- Log2 helper function
  --------------------------------------------------------------------
  FUNCTION log2(n : INTEGER) RETURN INTEGER IS
    VARIABLE i : INTEGER := 0;
    VARIABLE val : INTEGER := 1;
  BEGIN
    WHILE val < n LOOP
      val := val * 2;
      i := i + 1;
    END LOOP;
    RETURN i;
  END FUNCTION;

  --------------------------------------------------------------------
  -- Power of two check
  --------------------------------------------------------------------
  FUNCTION is_power_of_two(n : INTEGER) RETURN BOOLEAN IS
    VARIABLE val : INTEGER := 1;
  BEGIN
    WHILE val < n LOOP
      val := val * 2;
    END LOOP;
    RETURN (val = n);
  END FUNCTION;

  --------------------------------------------------------------------
  -- Constants and signals
  --------------------------------------------------------------------
  CONSTANT levels_c : INTEGER := log2(num_of_operands_g);

  TYPE adder_array_t IS ARRAY (0 TO num_of_operands_g * 2 - 2)
       OF STD_LOGIC_VECTOR(operand_width_g + levels_c - 1 DOWNTO 0);

  SIGNAL adder_array : adder_array_t;

BEGIN

  --------------------------------------------------------------------
  -- Assign operands_in to the first num_of_operands_g elements
  --------------------------------------------------------------------
  gen_input_assign : FOR i IN 0 TO num_of_operands_g - 1 GENERATE
  BEGIN
    adder_array(i) <= operands_in((i + 1) * operand_width_g - 1 DOWNTO i * operand_width_g);
  END GENERATE gen_input_assign;

  --------------------------------------------------------------------
  -- Generate adder tree
  --------------------------------------------------------------------
  gen_levels : FOR lvl IN 0 TO levels_c - 1 GENERATE
    CONSTANT num_adders : INTEGER := num_of_operands_g / (2 ** (lvl + 1));
    CONSTANT in_base    : INTEGER := 2 ** lvl - 1;
    CONSTANT out_base   : INTEGER := 2 ** (lvl + 1) - 1;
  BEGIN  -- <<<<<< this fixes the "Missing BEGIN" error

    gen_adders : FOR i IN 0 TO num_adders - 1 GENERATE
      CONSTANT in_idx_a : INTEGER := in_base + (2 * i);
      CONSTANT in_idx_b : INTEGER := in_base + (2 * i) + 1;
      CONSTANT out_idx  : INTEGER := out_base + i;
    BEGIN
      adder_inst : adder
        GENERIC MAP (
          operand_width_g => operand_width_g + lvl
        )
        PORT MAP (
          clk     => clk,
          rst_n   => rst_n,
          a_in    => adder_array(in_idx_a),
          b_in    => adder_array(in_idx_b),
          sum_out => adder_array(out_idx)
        );
    END GENERATE gen_adders;

  END GENERATE gen_levels;

  --------------------------------------------------------------------
  -- Final output
  --------------------------------------------------------------------
  sum_out <= adder_array(adder_array'RIGHT)(operand_width_g - 1 DOWNTO 0);

  --------------------------------------------------------------------
  -- Assertion: num_of_operands_g must be power of two and >= 2
  --------------------------------------------------------------------
  ASSERT (num_of_operands_g > 1) AND is_power_of_two(num_of_operands_g)
    REPORT "Number of operands must be a power of two and >= 2"
    SEVERITY FAILURE;

END structural;
