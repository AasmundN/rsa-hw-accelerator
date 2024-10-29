library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro_control is
  port (
    -- TODO: MISSING INTERNAL COUNTER. MOVE THE EXISTING TO I_COUNTER TO THE ARCHITECTURE.

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
    alu_b_select : out   std_logic
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
  signal i_counter         : std_logic_vector(7 downto 0); -- Used to store loop counter
  signal incr_i_counter    : std_logic;

begin

  main_state_process : process (clk, state) is
  begin

    out_reg_enable         <= '0';
    shift_reg_enable       <= '0';
    shift_reg_shift_enable <= '0';
    reset                  <= '0';

    output_valid   <= '0';
    alu_opcode     <= pass;
    alu_a_select   <= '0';
    alu_b_select   <= '0';
    incr_i_counter <= '0';

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
        incr_i_counter         <= '1';

        if (enable = '1') then
          if (to_integer(unsigned(i_counter)) < 255) then
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
            state_next <= save;
          else
            state_next <= valid;
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

        output_valid   <= '0';
        alu_opcode     <= pass;
        alu_a_select   <= '0';
        alu_b_select   <= '0';
        incr_i_counter <= '0';

        state_next <= idle;

    end case;

  end process main_state_process;

  update_state : process (reset, clk) is
  begin

    if (rising_edge(clk)) then
      if (reset = '1') then
        state <= idle;
      else
        state <= state_next;
      end if;
    end if;

  end process update_state;

  update_counter : process (reset, clk) is
  begin

    if (rising_edge(clk)) then
      if (reset = '1') then
        i_counter <= (others => '0');
      elsif (incr_i_counter = '1') then
        i_counter <= std_logic_vector(unsigned(i_counter) + 1);
      end if;
    end if;

  end process update_counter;

end architecture rtl;
