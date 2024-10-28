library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;


entity rsa_core_control is
    port(
        clk : in std_logic;
        reset : in std_logic;

        msgin_ready : out std_logic;
        msgin_valid : in std_logic;
        msgin_last : in std_logic;
        
        msgout_ready : in std_logic;
        msgout_valid : out std_logic;
        msgout_last : out std_logic;

        modmul_valid : in std_logic;
        modexp_in_ready : in std_logic;
        modexp_out_valid : in std_logic
    );
end entity;

architecture rtl of rsa_core_control is
    type state_type is (
        rdy, -- "wait" is a keyword and cannot be used (ref state_diagrams.xlsx)
        modmul, save_modmul,
        modexp_in, modexp_out,
        result_out -- "out" is a keyword and cannot be used (ref state_diagrams.xlsx)
    ) ;

    signal state, state_next : state_type;

    signal modmul_en : std_logic;
    signal modexp_out_ready : std_logic;
    signal modexp_in_valid : std_logic;

    signal in_reg_en, m_reg_en, last_reg_en, out_reg_en : std_logic;


begin
    main_process : process (clk, reset, state) is
        begin
            state_next <= rdy;

            msgin_ready <= '0';
            msgout_valid <= '0';

            modmul_en <= '0';
            modexp_out_ready <= '0';
            modexp_in_valid <= '0';

            in_reg_en <= '0';
            m_reg_en <= '0';
            last_reg_en <= '0';
            out_reg_en <= '0';

            -- TODO: Reset = 0 -> state = ready
            case(state) is
                when rdy =>
                    msgin_ready <= '1';
                    msgout_valid <= '0';
                    in_reg_en <= '1';
                    last_reg_en <= '1';

                    if (msgin_valid = '0') then
                       state_next <= rdy;
                    else
                        state_next <= modmul;
                    end if;

                when modmul =>
                    msgin_ready <= '0';
                    in_reg_en <= '0';
                    last_reg_en <= '0';
                    modmul_en <= '1';

                    if (modmul_valid = '0') then
                       state_next <= modmul;
                    else
                        state_next <= save_modmul;
                    end if;

                when save_modmul =>
                    m_reg_en <= '1';
                    modmul_en <= '0';
                    state_next <= modexp_in;

                when modexp_in =>
                    modexp_in_valid <= '1';

                    if (modexp_in_ready = '0') then
                       state_next <= modexp_in;
                    else
                        state_next <= modexp_out;
                    end if;
                when modexp_out =>
                    out_reg_en <= '1';
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
                        state_next <= rdy;
                    end if;

                when others =>
                    state_next <= rdy;

                    msgin_ready <= '0';
                    msgout_valid <= '0';

                    modmul_en <= '0';
                    modexp_out_ready <= '0';
                    modexp_in_valid <= '0';

                    in_reg_en <= '0';
                    m_reg_en <= '0';
                    last_reg_en <= '0';
                    out_reg_en <= '0';

            end case;
        end process main_process;




end architecture;