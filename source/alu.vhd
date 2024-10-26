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

  process (opcode, operand_a, operand_b) is
  begin

    -- Set less_than flag
    if (unsigned(operand_a) < unsigned(operand_b)) then
      less_than <= '1';
    else
      less_than <= '0';
    end if;

    -- Perform main ALU operation
    case (opcode) is

      when pass =>

        result <= operand_a;

      when sub =>

        result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));

      when add =>

        result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));

      when others =>

        result <= (others => '0');

    end case;

  end process;

end architecture rtl;
