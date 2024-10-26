library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modmul_datapath is
    generic (
        bit_width : integer := 256
      );
    port (
        --misc
        clk   : in std_logic;
        reset : in std_logic;

        --inputs
        out_reg_en : in std_logic;
        shift_reg_en: in std_logic; 
        shift_reg_shift_en : in std_logic; 
        
        alu_opcode: in std_logic;
        alu_a_sel: in std_logic;
        alu_b_sel: in std_logic;

        --outputs
        operand_a_last_bit: out std_logic;
        alu_a_less_than_b: out std_logic;        
    );
end entity;