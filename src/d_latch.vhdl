library ieee;
  use ieee.std_logic_1164.all;

entity d_latch is
  port (
    d   : in    std_logic;
    clk : in    std_logic;
    q   : out   std_logic
  );
end entity d_latch;

architecture rtl of d_latch is

begin

  process (d, clk) is
  begin

    if (clk = '1') then
      q <= d;
    end if;

  end process;

end architecture rtl;
