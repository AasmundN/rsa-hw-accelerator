-----------------------------------------------------------------------------
-- bit_width sized signal_in is masked by a bit_width sized mask of 1's or 0's depending on the value of set_mask_value.
-- the output is set to signal_out
--set_mask_values of 1 results in a bit_width sized mask of 1's
--set_mask_values of 0 results in a bit_width sized mask of 0's
----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity bitwise_masker is
    generic (
        bit_width : integer := 256
    );
    port (
        signal_in : in  std_logic_vector(bit_width - 1 downto 0);
        set_mask_values : in std_logic;

        signal_out : out std_logic_vector(bit_width - 1 downto 0)
    );
end entity bitwise_masker;


architecture rtl of bitwise_masker is
begin

    process (signal_in, set_mask_values)
    begin
        for i in 0 to bit_width - 1 loop
            signal_out(i) <= signal_in(i) and set_mask_values;
        end loop;
    end process;
end architecture;