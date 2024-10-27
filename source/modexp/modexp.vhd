library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modexp is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- Clock and reset
    -----------------------------------------------------------------------------
    clk   : in    std_logic;
    reset : in    std_logic;

    -----------------------------------------------------------------------------
    -- Modulus (n) of the modulo operation
    -----------------------------------------------------------------------------
    modulus : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Operands of modular exponentiation
    -----------------------------------------------------------------------------
    operand_m_bar : in    std_logic_vector(bit_width - 1 downto 0);
    operand_x_bar : in    std_logic_vector(bit_width - 1 downto 0);
    operand_e     : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Ready/valid handshake signals
    -----------------------------------------------------------------------------
    in_valid  : in    std_logic;
    in_ready  : out   std_logic;
    out_ready : in    std_logic;
    out_valid : out   std_logic
  );
end entity modexp;

architecture rtl of modexp is

begin

end architecture rtl;
