library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro_control is
  port (
    -- Clocks and reset
    clk   : in    std_logic;
    reset : out   std_logic;

    -- Entity enable/disable signals
    monpro_en  : out   std_logic;
    monpro_val : in    std_logic; -- Signals to external entities that the output is valid.

    -- Flags and counters
    alu_less_than : in    std_logic;
    is_odd        : in    std_logic;
    i_counter     : in    std_logic_vector(7 downto 0);

    -- Register control
    out_reg_en         : out   std_logic;
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

    monpro_en          <= '0';
    out_reg_en         <= '0';
    shift_reg_en       <= '0';
    shift_reg_shift_en <= '0';
    reset              <= '0';

    out_valid      <= '0';
    opcode         <= pass;
    alu_a_sel      <= '0';
    alu_b_sel      <= '0';
    incr_i_counter <= '0';

    case(state) is

      when idle =>

        out_valid          <= '0';
        shift_reg_shift_en <= '0';

        if (monpro_en = '1') then
          state_next <= start;
        else
          state_next <= idle;
        end if;

      when start =>

        shift_reg_en <= '0';
        reset        <= '1';

        if (monpro_en = '1') then
          state_next <= add_b;
        else
          state_next <= idle;
        end if;

      when add_b =>

        opcode     <= add;
        out_reg_en <= '1';
        alu_a_sel  <= '0';                                                   -- TODO: create type enum
        alu_b_sel  <= '1';                                                   -- TODO: create type enum

        if (is_odd = '1' and monpro_en = '1') then
          state_next <= add_n;
        else
          state_next <= shift;
        end if;

      when add_n =>

        opcode     <= add;
        out_reg_en <= '1';
        alu_a_sel  <= '0';                                                   -- TODO: create type enum
        alu_b_sel  <= '0';                                                   -- TODO: create type enum

        if (monpro_en = '1') then
          state_next <= shift;
        else
          state_next <= idle;
        end if;

      when shift =>

        opcode             <= pass;
        out_reg_en         <= '1';
        shift_reg_shift_en <= '1';
        alu_a_sel          <= '1';
        incr_i_counter     <= '1';

        if (monpro_en = '1') then
          if (to_integer(unsigned(i_counter)) < 255) then
            state_next <= add_b;
          else
            state_next <= comp;
          end if;
        else
          state_next <= idle;
        end if;

      when comp =>

        opcode             <= sub;
        out_reg_en         <= '0';
        shift_reg_shift_en <= '0';
        alu_a_sel          <= '0';
        alu_b_sel          <= '0';                                           -- TODO: verify this. Create enum.

        if (monpro_en = '1') then
          if (alu_less_than = '1') then
            state_next <= save;
          else
            state_next <= valid;
          end if;
        else
          state_next <= idle;
        end if;

      when save =>

        opcode     <= sub;
        out_reg_en <= '1';
        alu_a_sel  <= '0';
        alu_b_sel  <= '0';

        if (monpro_en = '1') then
          state_next <= valid;
        else
          state_next <= idle;
        end if;

      when valid =>

        out_reg_en <= '0';
        out_valid  <= '1';

        if (monpro_en = '1') then
          state_next <= valid;
        else
          state_next <= idle;
        end if;

      when others =>

        monpro_en          <= '0';
        out_reg_en         <= '0';
        shift_reg_en       <= '0';
        shift_reg_shift_en <= '0';
        reset              <= '0';

        out_valid      <= '0';
        opcode         <= pass;
        alu_a_sel      <= '0';
        alu_b_sel      <= '0';
        incr_i_counter <= '0';

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
