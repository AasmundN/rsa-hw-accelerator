library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modmul_control is
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : out   std_logic; -- Used to reset datapath

    -- Enable module
    enable : in    std_logic;

    -- Flags
    alu_less_than : in    std_logic;
    a_is_last     : in    std_logic;

    -- ALU control signals
    alu_opcode   : out   std_logic_vector(1 downto 0);
    alu_a_select : out   std_logic_vector(1 downto 0);
    alu_b_select : out   std_logic_vector(1 downto 0);

    -- Register control
    output_valid           : out   std_logic;
    out_reg_enable         : out   std_logic;
    shift_reg_enable       : out   std_logic;
    shift_reg_shift_enable : out   std_logic
  );
end entity modmul_control;

architecture rtl of modmul_control is
  type state_type is(
    idle, start,
    add_b, comp,
    save, shift,
    valid
  );

  -- Internal registers
  signal i_counter_r : std_logic_vector(1 downto 0);
  signal i_counter_increment_enable, i_counter_reset : std_logic;

begin

end architecture rtl;
