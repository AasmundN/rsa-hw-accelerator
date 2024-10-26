library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro_control is
  port (
    -- Clocks and reset
    clk   : in    std_logic;
    reset : in    std_logic;

    -- Entity enable/disable signals
    monpro_en  : out   std_logic;
    monpro_val : in    std_logic; -- Signals to external entities that the output is valid.

    -- Flags and counters
    alu_less_than : in    std_logic;
    is_odd        : in    std_logic;
    i_counter     : in    std_logic_vector(7 downto 0);

    -- Register control
    outreg_en          : out   std_logic;
    shift_reg_en       : out   std_logic;
    shift_reg_shift_en : out   std_logic;

    -- Data control
    out_valid      : out   std_logic;
    opcode         : out   alu_opcode_t;
    alu_a_sel      : out   std_logic;
    alu_b_sel      : out   std_logic;
    incr_i_counter : out   std_logic
  );
end entity monpro_control;

architecture rtl of monpro_control is

  type state_type is (
    idle, start,               -- Wait and initialise states
    add_b, add_n, shift, comp, -- Compute states
    save,                      -- Save data state
    valid                      -- Valid state
  );

  signal state, state_next : state_type;

begin

  main_state_process : process (state) is
  begin

    -- TODO: Sett defaults
    monpro_en          <= '0';
    outreg_en          <= '0';
    shift_reg_en       <= '0';
    shift_reg_shift_en <= '0';

    out_valid      <= '0';
    opcode         <= pass;
    alu_a_sel      <= '0';
    alu_b_sel      <= '0';
    incr_i_counter <= '0';

    case(state) is

      when idle =>

        out_valid <= '1';

      when start =>

        out_valid <= '1';

      when add_b =>

        out_valid <= '1';

      when add_n =>

        out_valid <= '1';

      when shift =>

        out_valid <= '1';

      when comp =>

        out_valid <= '1';

      when save =>

        out_valid <= '1';

      when valid =>

        out_valid <= '1';

      when others =>

        out_valid <= '1';

    end case;

  end process main_state_process;

  update_state : process (reset, clk) is
  begin

    if (reset = '0') then
      state <= idle;
    elsif (rising_edge(clk)) then
      state <= state_next;
    end if;

  end process update_state;

end architecture rtl;
