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
    is_last_reg_enable     : out   std_logic;

    -- e loop signals
    e_current_bit : in    std_logic;
    e_bit_is_last : in    std_logic;

    -- MUX control
    out_reg_in_select : out   std_logic_vector(1 downto 0);
    monpro_b_select   : out   std_logic_vector(1 downto 0);
    m_reg_in_select   : out   std_logic;

    -- Monpro control
    monpro_enable       : out   std_logic;
    monpro_output_valid : in    std_logic
  );
end entity modexp_control;

architecture rtl of modexp_control is

  type state_type is (
    waiting,                     -- Input handshake, set m and r_sq_modn in respective registers
    calc_m_bar,                  -- calculate m_bar and place in out_reg
    save_m_bar,                  -- latch m_bar into m_reg
    start,                       -- Removes leading zeros from e shiftreg
    monpro_xx, monpro_mx, shift, -- Repeated squaring
    monpro_x1,                   -- Prepare output
    valid                        -- Output handshake
  );

  signal state, state_next : state_type;

begin

  process (state, in_valid, monpro_output_valid, e_current_bit, e_bit_is_last, out_ready) is
  begin

    in_ready               <= '0';
    out_valid              <= '0';
    out_reg_enable         <= '0';
    shift_reg_enable       <= '0';
    shift_reg_shift_enable <= '0';
    m_reg_enable           <= '0';
    out_reg_in_select      <= "00";
    m_reg_in_select        <= '0';
    monpro_b_select        <= "00";
    monpro_enable          <= '0';
    is_last_reg_enable     <= '0';
    state_next             <= waiting;

    case (state) is

      when waiting =>

        in_ready          <= '1';
        out_reg_in_select <= "10";
        m_reg_in_select   <= '1';

        if (in_valid = '1') then
          m_reg_enable       <= '1';
          out_reg_enable     <= '1';
          shift_reg_enable   <= '1';
          is_last_reg_enable <= '1';
          state_next         <= calc_m_bar;
        else
          state_next <= waiting;
        end if;

      when calc_m_bar =>

        monpro_b_select <= "10";
        monpro_enable   <= '1';

        if (monpro_output_valid = '1') then
          monpro_enable  <= '0';
          out_reg_enable <= '1';
          state_next     <= save_m_bar;
        else
          state_next <= calc_m_bar;
        end if;

      when save_m_bar =>

        m_reg_enable      <= '1';
        out_reg_in_select <= "01";
        out_reg_enable    <= '1';

        state_next <= start;

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
          out_reg_enable <= '1';
          monpro_enable  <= '0';
          if (e_current_bit = '1') then
            state_next <= monpro_mx;
          else
            shift_reg_shift_enable <= '1';

            if (e_bit_is_last = '1') then
              state_next <= monpro_x1;
            else
              state_next <= monpro_xx;
            end if;
          end if;
        else
          state_next <= monpro_xx;
        end if;

      when monpro_mx =>

        monpro_enable   <= '1';
        monpro_b_select <= "10";

        if (monpro_output_valid = '1') then
          out_reg_enable         <= '1';
          monpro_enable          <= '0';
          shift_reg_shift_enable <= '1';

          if (e_bit_is_last = '1') then
            state_next <= monpro_x1;
          else
            state_next <= monpro_xx;
          end if;
        ----
        else
          state_next <= monpro_mx;
        end if;

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
          out_reg_enable <= '1';
          monpro_enable  <= '0';
          state_next     <= valid;
        else
          state_next <= monpro_x1;
        end if;

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
        out_reg_in_select      <= "00";
        monpro_b_select        <= "00";
        monpro_enable          <= '0';
        is_last_reg_enable     <= '0';
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
