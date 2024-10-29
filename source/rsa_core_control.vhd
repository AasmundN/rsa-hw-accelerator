library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity rsa_core_control is
  port (
    clk   : in    std_logic;
    reset : in    std_logic;

    msgin_ready : out   std_logic;
    msgin_valid : in    std_logic;
    msgin_last  : in    std_logic;

    msgout_ready : in    std_logic;
    msgout_valid : out   std_logic;
    msgout_last  : out   std_logic;

    modmul_valid     : in    std_logic;
    modexp_in_ready  : in    std_logic;
    modexp_out_valid : in    std_logic
  );
end entity rsa_core_control;

architecture rtl of rsa_core_control is

  type state_type is (
    waiting,       -- "wait" is a keyword and cannot be used (ref state_diagrams.xlsx)
    modmul, save_modmul,
    modexp_in, modexp_out,
    result_out -- "out" is a keyword and cannot be used (ref state_diagrams.xlsx)
  );

  signal state, state_next : state_type;

  signal modmul_en        : std_logic;
  signal modexp_out_ready : std_logic;
  signal modexp_in_valid  : std_logic;

  signal in_reg_en   : std_logic;
  signal m_reg_en    : std_logic;
  signal last_reg_en : std_logic;
  signal out_reg_enable  : std_logic;

begin

  main_process : process (state) is
  begin

    state_next <= waiting;

    msgin_ready  <= '0';
    msgout_valid <= '0';

    modmul_en        <= '0';
    modexp_out_ready <= '0';
    modexp_in_valid  <= '0';

    in_reg_en   <= '0';
    m_reg_en    <= '0';
    last_reg_en <= '0';
    out_reg_enable  <= '0';

    -- TODO: Reset = 0 -> state = ready
    case(state) is

      when waiting =>

        msgin_ready  <= '1';
        msgout_valid <= '0';
        in_reg_en    <= '1';
        last_reg_en  <= '1';

        if (msgin_valid = '0') then
          state_next <= waiting;
        else
          state_next <= modmul;
        end if;

      when modmul =>

        msgin_ready <= '0';
        in_reg_en   <= '0';
        last_reg_en <= '0';
        modmul_en   <= '1';

        if (modmul_valid = '0') then
          state_next <= modmul;
        else
          state_next <= save_modmul;
        end if;

      when save_modmul =>

        m_reg_en   <= '1';
        modmul_en  <= '0';
        state_next <= modexp_in;

      when modexp_in =>

        modexp_in_valid <= '1';

        if (modexp_in_ready = '0') then
          state_next <= modexp_in;
        else
          state_next <= modexp_out;
        end if;

      when modexp_out =>

        out_reg_enable       <= '1';
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

        modmul_en        <= '0';
        modexp_out_ready <= '0';
        modexp_in_valid  <= '0';

        in_reg_en   <= '0';
        m_reg_en    <= '0';
        last_reg_en <= '0';
        out_reg_enable  <= '0';

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


  last_message_control : process (clk) is
  begin

    if (rising_edge(clk)) then
      if (msgin_last = '1') then
        msgout_last <= '1';
      else
        msgout_last <= '0';
      end if;
    end if;

  end process last_message_control;

end architecture rtl;
