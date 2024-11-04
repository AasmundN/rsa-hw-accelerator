library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity msb_bitscanner is
  generic (
    bit_width : integer := 8
  );
  port (
    signal_in  : in    std_logic_vector(bit_width - 1 downto 0);
    signal_out : out   std_logic_vector(bit_width - 1 downto 0)
  );
end entity msb_bitscanner;

architecture rtl of msb_bitscanner is begin

  process (signal_in) is
  begin

    signal_out <= bitscanner(signal_in);

  end process;

end architecture rtl;

