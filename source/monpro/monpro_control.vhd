library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro_control is
  port (
    -- Clock
    clk   : in    std_logic;
    reset : out   std_logic;

    -- Module control
    enable       : in    std_logic;
    output_valid : out   std_logic;

    -- Flags and counters
    alu_less_than : in    std_logic;
    is_odd        : in    std_logic;

    -- Register control
    out_reg_enable         : out   std_logic;
    shift_reg_enable       : out   std_logic;
    shift_reg_shift_enable : out   std_logic;

    -- Data control
    alu_opcode   : out   alu_opcode_t;
    alu_a_select : out   std_logic;
    alu_b_select : out   std_logic;

    n_bit_is_last : in    std_logic
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

  main_state_process : process (all) is
  begin

    out_reg_enable         <= '0';
    shift_reg_enable       <= '0';
    shift_reg_shift_enable <= '0';
    reset                  <= '0';

    output_valid <= '0';
    alu_opcode   <= pass;
    alu_a_select <= '0';
    alu_b_select <= '0';

    state_next <= idle;

    case (state) is

      when idle =>

        shift_reg_enable <= '1';

        if (enable = '1') then
          state_next <= start;
        else
          state_next <= idle;
        end if;

      when start =>

        reset <= '1';

        if (enable = '1') then
          state_next <= add_b;
        else
          state_next <= idle;
        end if;

      when add_b =>

        alu_opcode     <= add;
        out_reg_enable <= '1';
        alu_b_select   <= '1';

        if (enable = '1') then
          if (is_odd = '1') then
            state_next <= add_n;
          else
            state_next <= shift;
          end if;
        else
          state_next <= idle;
        end if;

      when add_n =>

        alu_opcode     <= add;
        out_reg_enable <= '1';

        if (enable = '1') then
          state_next <= shift;
        else
          state_next <= idle;
        end if;

      when shift =>

        out_reg_enable         <= '1';
        shift_reg_shift_enable <= '1';
        alu_a_select           <= '1';

        if (enable = '1') then
          if (n_bit_is_last = '0') then
            state_next <= add_b;
          else
            state_next <= comp;
          end if;
        else
          state_next <= idle;
        end if;

      when comp =>

        alu_opcode <= sub;

        if (enable = '1') then
          if (alu_less_than = '1') then
            state_next <= valid;
          else
            state_next <= save;
          end if;
        else
          state_next <= idle;
        end if;

      when save =>

        alu_opcode     <= sub;
        out_reg_enable <= '1';

        if (enable = '1') then
          state_next <= valid;
        else
          state_next <= idle;
        end if;

      when valid =>

        output_valid <= '1';

        if (enable = '1') then
          state_next <= valid;
        else
          state_next <= idle;
        end if;

      when others =>

        out_reg_enable         <= '0';
        shift_reg_enable       <= '0';
        shift_reg_shift_enable <= '0';
        reset                  <= '0';

        output_valid <= '0';
        alu_opcode   <= pass;
        alu_a_select <= '0';
        alu_b_select <= '0';

        state_next <= idle;

    end case;

  end process main_state_process;

  update_state : process (reset, clk) is
  begin

    if (rising_edge(clk)) then
      state <= state_next;
    end if;

  end process update_state;

end architecture rtl;
