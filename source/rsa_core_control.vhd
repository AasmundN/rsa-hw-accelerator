library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity rsa_core_control is
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : in    std_logic;

    -- Core ready/valid signals
    msgin_ready : out   std_logic;
    msgin_valid : in    std_logic;

    msgout_ready : in    std_logic;
    msgout_valid : out   std_logic;

    -- Compute units ready/valid signals
    modmul_enable : out   std_logic;
    modmul_valid  : in    std_logic;

    modexp_in_ready : in    std_logic;
    modexp_in_valid : out   std_logic;

    modexp_out_ready : out   std_logic;
    modexp_out_valid : in    std_logic;

    -- Register enable signals
    is_msg_last_latch_enable : out   std_logic;
    in_reg_enable            : out   std_logic;
    m_reg_enable             : out   std_logic;
    out_reg_enable           : out   std_logic
  );
end entity rsa_core_control;

architecture rtl of rsa_core_control is

  type state_type is (
    waiting,   -- "wait" is a keyword and cannot be used (ref state_diagrams.xlsx)
    modmul, save_modmul,
    modexp_in, modexp_out,
    result_out -- "out" is a keyword and cannot be used (ref state_diagrams.xlsx)
  );

  signal state, state_next : state_type;

begin

  main_process : process (state) is
  begin

    state_next <= waiting;

    msgin_ready  <= '0';
    msgout_valid <= '0';

    modmul_enable    <= '0';
    modexp_out_ready <= '0';
    modexp_in_valid  <= '0';

    in_reg_enable            <= '0';
    m_reg_enable             <= '0';
    is_msg_last_latch_enable <= '0';
    out_reg_enable           <= '0';

    -- TODO: Reset = 0 -> state = ready
    case(state) is

      when waiting =>

        msgin_ready              <= '1';
        in_reg_enable            <= '1';
        is_msg_last_latch_enable <= '1';

        if (msgin_valid = '0') then
          state_next <= waiting;
        else
          state_next <= modmul;
        end if;

      when modmul =>

        modmul_enable <= '1';

        if (modmul_valid = '0') then
          state_next <= modmul;
        else
          state_next <= save_modmul;
        end if;

      when save_modmul =>

        m_reg_enable <= '1';
        state_next   <= modexp_in;

      when modexp_in =>

        modexp_in_valid <= '1';

        if (modexp_in_ready = '0') then
          state_next <= modexp_in;
        else
          state_next <= modexp_out;
        end if;

      when modexp_out =>

        out_reg_enable   <= '1';
        modexp_out_ready <= '1';

        if (modexp_out_valid = '0') then
          state_next <= modexp_out;
        else
          state_next <= result_out;
        end if;

      when result_out =>

        msgout_valid <= '1';

        if (msgout_ready = '0') then
          state_next <= result_out;
        else
          state_next <= waiting;
        end if;

      when others =>

        state_next <= waiting;

        msgin_ready  <= '0';
        msgout_valid <= '0';

        modmul_enable    <= '0';
        modexp_out_ready <= '0';
        modexp_in_valid  <= '0';

        in_reg_enable            <= '0';
        m_reg_enable             <= '0';
        is_msg_last_latch_enable <= '0';
        out_reg_enable           <= '0';

    end case;

  end process main_process;

  update_state : process (clk, reset) is
  begin

    if (reset = '0') then
      state <= waiting;
    elsif (rising_edge(clk)) then
      state <= state_next;
    end if;

  end process update_state;

end architecture rtl;
