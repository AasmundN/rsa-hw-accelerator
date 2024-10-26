-----------------------------------------------------------------------------
-- 3:1 binary multiplexer, with variable bitwidth of signals
----------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity mux3 is
  generic (
    bitwidth : integer := 256
  );
  port (
    a0 : in    std_logic_vector(bitwidth - 1 downto 0);
    a1 : in    std_logic_vector(bitwidth - 1 downto 0);
    a2 : in    std_logic_vector(bitwidth - 1 downto 0);

    b  : out   std_logic_vector(bitwidth - 1 downto 0);

    sel : out  std_logic_vector(1 downto 0)
  );
end entity mux3;

architecture rtl of mux3 is

begin

  process (all) is
  begin

    case(sel) is

      when "00" =>

        b <= a0;

      when "01" =>

        b <= a1;

        when "10" =>

        b <= a2;

      when others =>

        b <= (others => '-'); -- don't care

    end case;

  end process;

end architecture rtl;
