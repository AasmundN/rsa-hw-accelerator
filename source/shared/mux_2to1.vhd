-----------------------------------------------------------------------------
-- 2:1 binary multiplexer, with variable bitwidth of signals
----------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity mux_2to1 is
  generic (
    bit_width : integer := 256
  );
  port (
    a0 : in    std_logic_vector(bit_width - 1 downto 0);
    a1 : in    std_logic_vector(bit_width - 1 downto 0);
    b  : out   std_logic_vector(bit_width - 1 downto 0);

    sel : in    std_logic
  );
end entity mux_2to1;

architecture rtl of mux_2to1 is

begin

  process (a0, a1, sel) is
  begin

    case(sel) is

      when '0' =>

        b <= a0;

      when '1' =>

        b <= a1;

      when others =>

        b <= (others => '-'); -- don't care

    end case;

  end process;

end architecture rtl;
