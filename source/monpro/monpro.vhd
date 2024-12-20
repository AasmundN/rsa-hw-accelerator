library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- Clock
    -----------------------------------------------------------------------------
    clk : in    std_logic;

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
    -- Control signals
    -----------------------------------------------------------------------------
    enable       : in    std_logic;
    output_valid : out   std_logic
  );
end entity monpro;

architecture rtl of monpro is

  -- Internal reset signal
  signal reset : std_logic;

  -- ALU control signals
  signal alu_opcode    : alu_opcode_t;
  signal alu_b_select  : std_logic;
  signal alu_less_than : std_logic;

  -- Internal register control
  signal out_reg_enable         : std_logic;
  signal shift_reg_enable       : std_logic;
  signal shift_reg_shift_enable : std_logic;
  signal n_b_reg_enable         : std_logic;

  -- Used during execution of algorithm
  signal is_odd        : std_logic;
  signal n_bit_is_last : std_logic;

begin

  datapath : entity work.monpro_datapath(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk                    => clk,
      reset                  => reset,
      alu_opcode             => alu_opcode,
      alu_b_select           => alu_b_select,
      alu_less_than          => alu_less_than,
      out_reg_enable         => out_reg_enable,
      shift_reg_enable       => shift_reg_enable,
      shift_reg_shift_enable => shift_reg_shift_enable,
      n_b_reg_enable         => n_b_reg_enable,
      modulus                => modulus,
      operand_a              => operand_a,
      operand_b              => operand_b,
      result                 => result,
      is_odd                 => is_odd,
      n_bit_is_last          => n_bit_is_last
    );

  control : entity work.monpro_control(rtl)
    port map (
      clk                    => clk,
      reset                  => reset,
      enable                 => enable,
      alu_less_than          => alu_less_than,
      is_odd                 => is_odd,
      n_bit_is_last          => n_bit_is_last,
      out_reg_enable         => out_reg_enable,
      shift_reg_enable       => shift_reg_enable,
      shift_reg_shift_enable => shift_reg_shift_enable,
      n_b_reg_enable         => n_b_reg_enable,
      output_valid           => output_valid,
      alu_opcode             => alu_opcode,
      alu_b_select           => alu_b_select
    );

end architecture rtl;
