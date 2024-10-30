library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;

  -- Include shared utils
  use work.utils.all;

entity alu_tb is
  generic (
    bit_width     : integer := 32;
    test_set_size : integer := 256
  );
end entity alu_tb;

architecture func of alu_tb is

  -- ALU inputs and output
  signal operand_a : std_logic_vector(bit_width - 1 downto 0);
  signal operand_b : std_logic_vector(bit_width - 1 downto 0);
  signal result    : std_logic_vector(bit_width - 1 downto 0);

  -- ALU control and flags
  signal opcode    : alu_opcode_t;
  signal less_than : std_logic;

  function opcode_to_string (
    opcode : alu_opcode_t
  )
    return string is
  begin

    case opcode is

      when pass =>

        return "pass";

      when add =>

        return "add";

      when sub =>

        return "sub";

    end case;

  end function opcode_to_string;

begin

  dut : entity work.alu
    generic map (
      bit_width => bit_width
    )
    port map (
      opcode    => opcode,
      operand_a => operand_a,
      operand_b => operand_b,
      less_than => less_than,
      result    => result
    );

  test_sequencer : process is

    -- Test inputs
    variable test_opcode : alu_opcode_t;
    variable test_a      : std_logic_vector(bit_width - 1 downto 0);
    variable test_b      : std_logic_vector(bit_width - 1 downto 0);

    -- Expected outputs
    variable expected_result    : std_logic_vector(bit_width - 1 downto 0);
    variable expected_less_than : std_logic;

  begin

    -- Testbench config
    set_alert_stop_limit(ERROR, 5);

    log(ID_LOG_HDR_LARGE, "Running alu_tb");

    -- Apply initial values
    operand_a <= (others => '0');
    operand_b <= (others => '0');
    opcode    <= add;

    wait for 1 ns;

    for i in 0 to test_set_size - 1 loop

      -- Generate random inputs
      test_opcode := alu_opcode_t'val(random(0, 2));
      test_a      := random(operand_a'length);
      test_b      := random(operand_b'length);

      log(ID_LOG_HDR, "Running test " & to_string(i));

      -- Calculate expected outputs
      case test_opcode is

        when pass =>

          expected_result := test_a;

        when add =>

          expected_result := std_logic_vector(unsigned(test_a) + unsigned(test_b));

        when sub =>

          expected_result := std_logic_vector(unsigned(test_a) - unsigned(test_b));

      end case;

      if (unsigned(test_a) < unsigned(test_b)) then
        expected_less_than := '1';
      else
        expected_less_than := '0';
      end if;

      log(
          "Opcode        => " & opcode_to_string(test_opcode) & "\n" &
          "Operand a     => " & to_string(test_a, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Operand b     => " & to_string(test_b, HEX, AS_IS, INCL_RADIX) & "\n"
        );

      -- Apply test values
      operand_a <= test_a;
      operand_b <= test_b;
      opcode    <= test_opcode;

      wait for 1 ns;

      -- Verify result and less_than
      check_value(result, expected_result, "Check ALU output");
      check_value(less_than, expected_less_than, "Check ALU less_than");

    end loop;

    log(ID_LOG_HDR_LARGE, "End of simulation");

    report_alert_counters(void);

    std.env.stop;
    wait;

  end process test_sequencer;

end architecture func;
