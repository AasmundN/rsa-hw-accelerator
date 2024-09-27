library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.env.all;

library src;
  use src.all;

entity prime_tb is
end entity prime_tb;

architecture behaviour of prime_tb is

  signal input   : std_logic_vector(3 downto 0);
  signal isprime : std_logic;

  component prime is
    port (
      input   : in    std_logic_vector(3 downto 0);
      isprime : out   std_logic
    );
  end component prime;

  for DUT: prime use entity src.prime(behaviour);

begin

  dut : component prime
    port map (
      input   => input,
      isprime => isprime
    );

  process is
  begin

    for i in 0 to 15 loop

      input <= std_logic_vector(to_unsigned(i, 4));
      wait for 10 ns;
      report "input = " & to_string(to_integer(unsigned(input))) &
             " isprime = " & to_string(isprime);

    end loop;

    finish(0);

  end process;

end architecture behaviour;
