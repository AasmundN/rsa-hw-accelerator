library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity prime is
  port (
    input   : in    std_logic_vector(3 downto 0);
    isprime : out   std_logic
  );
end entity prime;

architecture rtl of prime is

begin

  func : process (input) is
  begin

    case input is

      when x"1" | x"2" | x"3" | x"5" | x"7" | x"b" | x"d" =>

        isprime <= '1';

      when others =>

        isprime <= '0';

    end case;

  end process func;

end architecture rtl;
