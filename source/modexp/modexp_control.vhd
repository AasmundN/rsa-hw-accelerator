library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modexp_control is
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : in    std_logic;

    -- Ready/valid handshake signals
    in_valid  : in    std_logic;
    in_ready  : out   std_logic;
    out_ready : in    std_logic;
    out_valid : out   std_logic;

    -- Internal register control
    out_reg_enable         : out   std_logic;
    shift_reg_enable       : out   std_logic;
    shift_reg_shift_enable : out   std_logic;
    m_reg_enable           : out   std_logic;

    -- e loop signals
    e_current_bit : in    std_logic;
    e_bit_is_last : in    std_logic;

    -- MUX control
    out_reg_in_select : out   std_logic;
    monpro_b_select   : out   std_logic_vector(1 downto 0);

    -- Monpro control
    monpro_enable       : out   std_logic;
    monpro_output_valid : in    std_logic
  );
end entity modexp_control;

architecture rtl of modexp_control is

  type state_type is (
    waiting,                                       -- Input handshake
    start,                                         -- Removes leading zeros from e shiftreg
    monpro_xx, save_xx, monpro_mx, save_mx, shift, -- Repeated squaring
    monpro_x1, save_x1,                            -- Prepare output
    valid                                          -- Output handshake
  );

  signal state, state_next : state_type;

begin

  process (all) is
  begin

    in_ready               <= '0';
    out_valid              <= '0';
    out_reg_enable         <= '0';
    shift_reg_enable       <= '0';
    shift_reg_shift_enable <= '0';
    m_reg_enable           <= '0';
    out_reg_in_select      <= '0';
    monpro_b_select        <= "00";
    monpro_enable          <= '0';
    state_next             <= waiting;

    case (state) is

      when waiting =>

        in_ready          <= '1';
        m_reg_enable      <= '1';
        out_reg_enable    <= '1';
        shift_reg_enable  <= '1';
        out_reg_in_select <= '1';

        if (in_valid = '1') then
          state_next <= start;
        else
          state_next <= waiting;
        end if;

      when start =>

        if (e_current_bit = '1') then
          state_next <= monpro_xx;
        else
          shift_reg_shift_enable <= '1';
          state_next             <= start;
        end if;

      when monpro_xx =>

        monpro_enable <= '1';

        if (monpro_output_valid = '1') then
          state_next <= save_xx;
        else
          state_next <= monpro_xx;
        end if;

      when save_xx =>

        out_reg_enable <= '1';

        if (e_current_bit = '1') then
          state_next <= monpro_mx;
        else
          state_next <= shift;
        end if;

      when monpro_mx =>

        monpro_enable   <= '1';
        monpro_b_select <= "10";

        if (monpro_output_valid = '1') then
          state_next <= save_mx;
        else
          state_next <= monpro_mx;
        end if;

      when save_mx =>

        out_reg_enable <= '1';
        state_next     <= shift;

      when shift =>

        shift_reg_shift_enable <= '1';

        if (e_bit_is_last = '1') then
          state_next <= monpro_x1;
        else
          state_next <= monpro_xx;
        end if;

      when monpro_x1 =>

        monpro_enable   <= '1';
        monpro_b_select <= "01";

        if (monpro_output_valid = '1') then
          state_next <= save_x1;
        else
          state_next <= monpro_x1;
        end if;

      when save_x1 =>

        out_reg_enable <= '1';
        state_next     <= valid;

      when valid =>

        out_valid <= '1';

        if (out_ready = '1') then
          state_next <= waiting;
        else
          state_next <= valid;
        end if;

      when others =>

        in_ready               <= '0';
        out_valid              <= '0';
        out_reg_enable         <= '0';
        shift_reg_enable       <= '0';
        shift_reg_shift_enable <= '0';
        m_reg_enable           <= '0';
        out_reg_in_select      <= '0';
        monpro_b_select        <= "00";
        monpro_enable          <= '0';
        state_next             <= waiting;

    end case;

  end process;

  update_state : process (reset, clk) is
  begin

    if (rising_edge(clk)) then
      if (reset = '1') then
        state <= waiting;
      else
        state <= state_next;
      end if;
    end if;

  end process update_state;

end architecture rtl;
