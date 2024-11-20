library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity alu is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- ALU operation code
    -----------------------------------------------------------------------------
    opcode : in    alu_opcode_t;

    -----------------------------------------------------------------------------
    -- ALU operands
    -----------------------------------------------------------------------------
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);
    operand_c : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Outputs '1' if operand_a is less than operand_b
    -----------------------------------------------------------------------------
    less_than : out   std_logic;

    -----------------------------------------------------------------------------
    -- ALU operation output
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0)
  );
end entity alu;

architecture rtl of alu is

begin

  -- Perform main ALU operation
  process (opcode, operand_a, operand_b) is
  begin

    case (opcode) is

      when pass =>

        result <= operand_a;

      when sub =>

        result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b) - to_unsigned(0, bit_width));

      when add =>

        result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b) + unsigned(operand_c));

      when others =>

        result <= (others => '0');

    end case;

  end process;

  -- Set less_than flag
  process (operand_a, operand_b) is
  begin

    if (unsigned(operand_a) < unsigned(operand_b)) then
      less_than <= '1';
    else
      less_than <= '0';
    end if;

  end process;

end architecture rtl;
