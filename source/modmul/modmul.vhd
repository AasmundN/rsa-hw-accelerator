library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modmul is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- Modulus (n) of the modulo operation
    -----------------------------------------------------------------------------
    modulus : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Operands of Montgomery product
    -----------------------------------------------------------------------------
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0)

    -----------------------------------------------------------------------------
    -- control signals
    -----------------------------------------------------------------------------
    clk: in std_logic;
    
    enable : in std_logic;
    output_valid : out std_logic

  );
end entity modmul;

architecture rtl of modmul is

begin

end architecture rtl;