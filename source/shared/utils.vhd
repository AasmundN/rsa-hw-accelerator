library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package utils is

  type alu_opcode_t is (pass, add, sub);

  -- Function for calculating Mongomery product

  function monpro (
    a,
    b,
    n : std_logic_vector
  ) return std_logic_vector;

end package utils;

package body utils is

  function monpro (
    a,
    b,
    n : std_logic_vector
  )
  return std_logic_vector
  is

    variable u     : std_logic_vector(n'length + 2 downto 0) := (others => '0');
    variable a_vec : std_logic_vector(n'length - 1 downto 0) := (others => '0');

  begin

    a_vec := a;

    for i in a_vec'reverse_range loop

      if (a_vec(i) = '1') then
        u := std_logic_vector(unsigned(u) + unsigned(b));
      end if;

      if ((unsigned(u) mod 2) = 1) then
        u := std_logic_vector(unsigned(u) + unsigned(n));
      end if;

      u := std_logic_vector(unsigned(u) / 2);

    end loop;

    if (unsigned(u) >= unsigned(n)) then
      u := std_logic_vector(unsigned(u) - unsigned(n));
    end if;

    return u(n'length - 1 downto 0);

  end function monpro;

end package body utils;
