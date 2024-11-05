library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rsa_core_input_control is
    generic(
        c_block_size : integer := 256;
        num_cores : integer := 6
    );
    port(
        -- Clock and reset
        clk : in std_logic;
        reset : in std_logic;

        -- AXI Interface
        msgin_valid : in    std_logic;
        msgin_ready : out   std_logic;

        -- Modexp control
        modexp_in_ready  : in   std_logic_vector(num_cores - 1 downto 0);
        modexp_in_valid  : out    std_logic_vector(num_cores - 1 downto 0);
        modexp_out_ready : out    std_logic_vector(num_cores - 1 downto 0);
        modexp_out_valid : in   std_logic_vector(num_cores - 1 downto 0)
    );

end rsa_core_input_control;

architecture rtl of rsa_core_input_control is
    signal core_id_reg : std_logic_vector(num_cores - 1 downto 0);
    signal m_reg_enable : std_logic_vector;

begin
end architecture rtl;