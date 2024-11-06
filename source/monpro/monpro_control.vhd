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
    idle,                        -- Wait and initialise states
    add_b, add_n, shift, reduce, -- Compute states
    valid                        -- Valid state
  );

  signal state, state_next : state_type;

begin

  main_state_process : process (state, enable, is_odd, n_bit_is_last, alu_less_than) is
  begin

    out_reg_enable         <= '0';
    shift_reg_enable       <= '0';
    shift_reg_shift_enable <= '0';
    reset                  <= '0';

    output_valid <= '0';
    alu_opcode   <= pass;
    alu_a_select <= '1';
    alu_b_select <= '0';

    state_next <= idle;

    case (state) is

      when idle =>

        shift_reg_enable <= '1';

        if (enable = '1') then
          reset      <= '1';
          state_next <= add_b;
        else
          state_next <= idle;
        end if;

      when add_b =>

        alu_opcode     <= add;
        out_reg_enable <= '1';
        alu_b_select   <= '1';

        if (is_odd = '1') then
          state_next <= add_n;
        else
          shift_reg_shift_enable <= '1';
          if (n_bit_is_last = '0') then
            state_next <= add_b;
          else
            state_next <= reduce;
          end if;
        end if;

      when add_n =>

        alu_opcode             <= add;
        out_reg_enable         <= '1';
        alu_a_select           <= '0';
        shift_reg_shift_enable <= '1';

        if (n_bit_is_last = '0') then
          state_next <= add_b;
        else
          state_next <= reduce;
        end if;

      when reduce =>

        out_reg_enable <= '1';

        if (alu_less_than = '0') then
          alu_opcode <= sub;
        else
          alu_opcode <= pass;
        end if;

        state_next <= valid;

      when valid =>

        output_valid <= '1';
        state_next   <= idle;

      when others =>

        out_reg_enable         <= '0';
        shift_reg_enable       <= '0';
        shift_reg_shift_enable <= '0';
        reset                  <= '0';

        output_valid <= '0';
        alu_opcode   <= pass;
        alu_a_select <= '1';
        alu_b_select <= '0';

        state_next <= idle;

    end case;

  end process main_state_process;

  update_state : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (enable = '1') then
        state <= state_next;
      else
        state <= idle;
      end if;
    end if;

  end process update_state;

end architecture rtl;
