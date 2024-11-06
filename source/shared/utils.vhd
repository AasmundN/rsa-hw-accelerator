library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package utils is

  type alu_opcode_t is (pass, add, sub);

  -- Returns a zeroed logic vector where the most significant (non-zero) bit of "a" is preserved

  function bitscanner (
    a : std_logic_vector
  ) return std_logic_vector;

  -- Reverses the bit order of a logic vector

  function flip_logic_vector (
    vec : std_logic_vector
  ) return std_logic_vector;

  -- Calculate Mongomery product
  -- It is assumed that a and b are less than n
  -- and n is an odd number

  function monpro (
    a,
    b,
    n : std_logic_vector
  ) return std_logic_vector;

  -- Calculate modular multiplication
  -- Sizes of a, b, and n must be within bit_width

  function modmul (
    a,
    b,
    n : std_logic_vector;
    bit_width : integer
  ) return std_logic_vector;

  -- Calculate modular exponentiation
  -- It is assumed that m and e are less than n
  -- and that n is an odd number

  function modexp (
    m,
    e,
    n : std_logic_vector
  ) return std_logic_vector;

  -- Calculates the minimum required bits to represent a number "n"

  function get_bit_width (
    n : integer
  ) return integer;

end package utils;

package body utils is

  function bitscanner (
    a : std_logic_vector
  ) return std_logic_vector
    is

    variable a_flipped          : std_logic_vector(a'range) := flip_logic_vector(a);
    variable a_flipped_inverted : std_logic_vector(a'range) := (others => '0');

    variable flipped_result : std_logic_vector(a'range) := (others => '0');
    variable result         : std_logic_vector(a'range) := (others => '0');

  begin

    -- Step 1: result_flipped = a_flipped AND ((NOT a_flipped) + 1)
    a_flipped_inverted := not a_flipped;
    flipped_result     := a_flipped and std_logic_vector(unsigned(a_flipped_inverted) + 1);

    -- Step 2: Flip(result_flipped)
    result := flip_logic_vector(flipped_result);

    return result;

  end function bitscanner;

  function flip_logic_vector (
    vec : std_logic_vector
  ) return std_logic_vector is

    variable vec_flipped : std_logic_vector(vec'range) := ((others => '0'));

  begin

    for i in vec'range loop

      vec_flipped(i) := vec(vec'high - i + vec'low);

    end loop;

    return vec_flipped;

  end function flip_logic_vector;

  function monpro (
    a,
    b,
    n : std_logic_vector
  )
  return std_logic_vector
  is

    variable u           : std_logic_vector(n'length + 2 downto 0) := (others => '0');
    variable a_vec       : std_logic_vector(n'length - 1 downto 0) := (others => '0');
    variable n_shift_reg : std_logic_vector(n'length - 1 downto 0) := (others => '0');

  begin

    a_vec       := a;
    n_shift_reg := bitscanner(n);

    for i in a_vec'reverse_range loop

      if (a_vec(i) = '1') then
        u := std_logic_vector(unsigned(u) + unsigned(b));
      end if;

      if ((unsigned(u) mod 2) = 1) then
        u := std_logic_vector(unsigned(u) + unsigned(n));
      end if;

      u := std_logic_vector(unsigned(u) / 2);

      if (n_shift_reg(i) = '1') then
        exit;
      end if;

    end loop;

    if (unsigned(u) >= unsigned(n)) then
      u := std_logic_vector(unsigned(u) - unsigned(n));
    end if;

    return u(n'length - 1 downto 0);

  end function monpro;

  function modmul (
    a,
    b,
    n : std_logic_vector;
    bit_width : integer
  ) return std_logic_vector
  is

    variable p : std_logic_vector(bit_width + 2 downto 0) := (others => '0');

  begin

    for i in b'range loop

      p := std_logic_vector(shift_left(unsigned(p), 1));

      if (b(i) = '1') then
        p := std_logic_vector(unsigned(p) + unsigned(a));
      end if;

      p := std_logic_vector(resize(unsigned(p) mod unsigned(n), p'length));

    end loop;

    return p(bit_width - 1 downto 0);

  end function modmul;

  function modexp (
    m,
    e,
    n : std_logic_vector
  ) return std_logic_vector
  is

    variable c : std_logic_vector(n'length - 1 downto 0) := (others => '0');

  begin

    if (e(e'length - 1) = '1') then
      c := m;
    else
      c(0) := '1';
    end if;

    for i in e'length - 1 downto 0 loop

      c := modmul(c, c, n, n'length);

      if (e(i) = '1') then
        c := modmul(c, m, n, n'length);
      end if;

    end loop;

    return c;

  end function modexp;

  -- Calculates the ceiling of the base-2 logarithm for a given "n"

  function get_bit_width (
    n : integer
  ) return integer is

    variable result : integer := 0;
    variable temp   : integer := n - 1;

  begin

    while temp > 0 loop

      temp   := temp / 2;
      result := result + 1;

    end loop;

    return result;

  end function get_bit_width;

end package body utils;
