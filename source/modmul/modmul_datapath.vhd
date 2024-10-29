library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity modmul_datapath is
  generic (
    bit_width : integer := 256
  );
  port (
    -- misc
    clk   : in    std_logic;
    reset : in    std_logic;

    -- main input and outputs
    modulus   : in    std_logic_vector(bit_width - 1 downto 0);
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);
    result    : out   std_logic_vector(bit_width - 1 downto 0);

    -- control inputs
    out_reg_enable         : in    std_logic;
    shift_reg_enable       : in    std_logic;
    shift_reg_shift_enable : in    std_logic;

    alu_opcode   : in    alu_opcode_t;
    alu_a_select : in    std_logic;
    alu_b_select : in    std_logic;

    -- control outputs
    operand_a_last_bit : out   std_logic;
    alu_less_than      : out   std_logic
  );
end entity modmul_datapath;

architecture rtl of modmul_datapath is

  -- internal registers
  signal a_reg_r             : std_logic_vector(bit_width - 1 downto 0);
  signal a_last_reg_r        : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_r            : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_left_shifted : std_logic_vector(bit_width - 1 downto 0); -- register on input-side A of alu

  signal bit_scanner_out : std_logic_vector(bit_width - 1 downto 0);

  -- b anded with ith bit of a
  signal and_b_a : std_logic_vector(bit_width - 1 downto 0);

  -- ALU inputs and outputs
  signal alu_a      : std_logic_vector(bit_width - 1 downto 0);
  signal alu_b      : std_logic_vector(bit_width - 1 downto 0);
  signal alu_result : std_logic_vector(bit_width - 1 downto 0);

begin

  process (all)
  begin
    
  end process;


end architecture rtl;

