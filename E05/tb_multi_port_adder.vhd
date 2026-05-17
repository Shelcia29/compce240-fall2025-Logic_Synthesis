-------------------------------------------------------------------------------
-- Title      : COMP.CE.240, Exercise 05
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_multi_port_adder.vhd
-- Author     : Ashinsani, Shelcia
-- Company    : TAU
-- Edited     : 2025-09-19
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Tests all combinations of summing 3-bit inputs
-------------------------------------------------------------------------------
-- Copyright (c) 2025
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description

-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; 

entity tb_multi_port_adder is
	generic (
  		operand_width_g :integer := 3 
	);
end tb_multi_port_adder;


architecture testbench of tb_multi_port_adder is

  -- Define constants
  constant clk_period_c : time    := 10 ns;  
  constant num_of_operands_c    : integer := 4;
  constant duv_delay_c   : integer := 2;


  -- Create signals
  signal clk   : std_logic := '0';
  signal rst_n : std_logic := '0';

  signal operand_r : std_logic_vector((operand_width_g*num_of_operands_c)-1 DOWNTO 0);
  signal sum : std_logic_vector(operand_width_g-1 DOWNTO 0);
  signal output_valid_r : std_logic_vector(duv_delay_c+1-1 downto 0);

--Define three files whose types are text
 
  file input_f : text open READ_MODE is "input.txt";
  file ref_results_f : text open READ_MODE is "ref_results.txt";
  file output_f : text open WRITE_MODE is "output.txt";
  file ref_results_4b_f : text open READ_MODE is "ref_results_4b.txt";



  component multi_port_adder

	generic (
    		operand_width_g : INTEGER := 16;
		num_of_operands_g : INTEGER := 4 
  	);
	port (
		clk     : in  std_logic;
    		rst_n   : in  std_logic;
    		operands_in : in std_logic_vector ((operand_width_g*num_of_operands_g)-1 downto 0);
    		sum_out : out std_logic_vector(operand_width_g-1 downto 0)
	);
  end component;



begin  -- testbench


--Assignment of not clk to clk-signal 
  clk_gen : process (clk, rst_n)
  begin  
    clk <= not clk after clk_period_c/2;
  end process clk_gen;

--Set the reset-signal 
    rst_n <= '1' after clk_period_c*4;

 
--instantiate multiport adder
   multi_port_adder_1 : entity work.multi_port_adder

     generic map(
        operand_width_g => operand_width_g,
        num_of_operands_g => num_of_operands_c
     )
     port map(
	clk => clk,
	rst_n => rst_n,
	operands_in => operand_r,
	sum_out => sum
    );

-- synchronous process for reading input files
    input_reader : process(clk, rst_n)
	variable line_v : line;
	variable var_a, var_b, var_c, var_d : integer;
   
    begin
	
	if rst_n = '0' then
		operand_r        <= (others => '0');
        	output_valid_r    <= (others => '0');

		
	elsif rising_edge(clk) then       

		output_valid_r <= output_valid_r(duv_delay_c-1 downto 0) & '1';

		if not endfile(input_f) then
			readline(input_f, line_v);
	  
			read(line_v, var_a);
	  		read(line_v, var_b);
	  		read(line_v, var_c);
	  		read(line_v, var_d);
          
	  		operand_r <= std_logic_vector(to_signed(var_a, operand_width_g)) & std_logic_vector(to_signed(var_b, operand_width_g)) & std_logic_vector(to_signed(var_c, operand_width_g)) & std_logic_vector(to_signed(var_d, operand_width_g));
         	else
	   		operand_r <= (others => '0');
	 	end if;
	end if;
	  
    end process input_reader;

--checker : synchronous process

    checker : process(clk)
	
	variable line_v   : line;
    	variable out_line : line;
    	variable ref_v    : integer;
    	variable dut_int  : integer;
  
    begin

	if rst_n = '0' then
        	null;

	elsif rising_edge(clk) then
        
        	   if output_valid_r(duv_delay_c) = '1' then

          
          		if not endfile(ref_results_f) then
            			readline(ref_results_f, line_v);
            			read(line_v, ref_v);
        
            			dut_int := to_integer(signed(sum));
            
            			write(out_line, dut_int);
            			writeline(output_f, out_line);

            			-- check equality
            			assert (dut_int = ref_v)
              				report "Mismatch: expected " & integer'image(ref_v) & " got " & integer'image(dut_int)
              				severity error;

          		else
            			assert false report "Simulation done: reference file EOF reached" severity failure;
          		end if;

		   end if;
      		
	end if;
    	
  end process checker;



end testbench;
