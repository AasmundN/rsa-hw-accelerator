library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


entity rsa_core_control is
    port(
        clk : out std_logic;
        reset : in std_logic;

        msgin_ready : out std_logic;
        msgin_valid : in std_logic;
        msgin_last : in std_logic;
        
        msgout_ready : in std_logic;
        msout_valid : out std_logic;
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

    signal state, next_state : state_type;

    signal modmul_en : std_logic;
    signal modexp_out_ready : std_logic;
    signal modexp_in_valid : std_logic;

    signal in_reg_en, m_reg_en, last_reg_en, out_reg_en : std_logic;


begin
    next_state <= rdy;
    modmul_en <= '0';
    modmul_valid <= '0';
    modexp_in_ready <= '0';

end architecture;