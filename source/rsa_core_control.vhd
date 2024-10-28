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
        msgout_last : out std_logic
    );
end entity;

architecture rtl of rsa_core_control is
    signal modmul_en, modmul_valid : std_logic;
    signal modexp_in_ready, modexp_out_ready : std_logic;
    signal modexp_in_valid, modexp_out_valid : std_logic;

    signal in_reg_en, m_reg_en, last_reg_en, out_reg_en : std_logic;
begin

end architecture;