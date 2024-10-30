library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity msb_bitscanner is
  generic (
    bit_width : integer := 256
  );
  port (
    signal_in  : in    std_logic_vector(bit_width - 1 downto 0);
    signal_out : out   std_logic_vector(bit_width - 1 downto 0)
  );
end entity msb_bitscanner;

architecture rtl of msb_bitscanner is begin

  process (signal_in) is

    variable temp_output : std_logic_vector(bit_width - 1 downto 0) := (others => '0');

  begin

    for i in signal_in'reverse_range loop

      if (signal_in(i) = '1') then
        temp_output(i) := '1';
        exit;
      end if;

    end loop;

    signal_out <= temp_output;

  end process;

end architecture rtl;

