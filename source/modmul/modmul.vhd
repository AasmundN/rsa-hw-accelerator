library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity modmul is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- Modulus (n) of the modulo operation
    -----------------------------------------------------------------------------
    modulus : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Operands of Montgomery product
    -----------------------------------------------------------------------------
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- control signals
    -----------------------------------------------------------------------------
    clk : in    std_logic;

    enable       : in    std_logic;
    output_valid : out   std_logic
  );
end entity modmul;

architecture rtl of modmul is

  signal reset     : std_logic;
  signal a_is_last : std_logic; -- Check if this is internal or external @aasmund

  signal alu_less_than              : std_logic;
  signal alu_opcode                 : alu_opcode_t;
  signal alu_a_select, alu_b_select : std_logic;

  signal out_reg_enable         : std_logic;
  signal shift_reg_enable       : std_logic;
  signal shift_reg_shift_enable : std_logic;

begin

  control : entity work.modmul_control(rtl)
    port map (
      clk                    => clk,
      reset                  => reset,
      enable                 => enable,
      a_is_last              => a_is_last,
      alu_less_than          => alu_less_than,
      alu_opcode             => alu_opcode,
      alu_a_select           => alu_a_select,
      alu_b_select           => alu_b_select,
      output_valid           => output_valid,
      out_reg_enable         => out_reg_enable,
      shift_reg_enable       => shift_reg_enable,
      shift_reg_shift_enable => shift_reg_shift_enable
    );

end architecture rtl;
