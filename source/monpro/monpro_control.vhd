library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity monpro_control is
  port (
    -----------------------------------------------------------------------------
    -- Clocks and reset
    -----------------------------------------------------------------------------
    clk   : in    std_logic;
    reset : in    std_logic;

    -----------------------------------------------------------------------------
    -- Entity enable/disable signals
    -----------------------------------------------------------------------------
    monpro_en  : out   std_logic;
    monpro_val : in    std_logic; -- Signals to external entities that the output is valid.

    -----------------------------------------------------------------------------
    -- Flags and counters
    -----------------------------------------------------------------------------
    alu_less_than : in    std_logic;
    is_odd        : in    std_logic;
    i_counter     : in    std_logic_vector(7 downto 0);

    -----------------------------------------------------------------------------
    -- Register control
    -----------------------------------------------------------------------------
    outreg_en          : out   std_logic;
    shift_reg_en       : out   std_logic;
    shift_reg_shift_en : out   std_logic;

    -----------------------------------------------------------------------------
    -- Data control
    -----------------------------------------------------------------------------
    out_valid      : out   std_logic;
    opcode         : out   std_logic_vector(1 downto 0);
    alu_a_sel      : out   std_logic;
    alu_b_sel      : out   std_logic;
    incr_i_counter : out   std_logic
  );
end entity monpro_control;
