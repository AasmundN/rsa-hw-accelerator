library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;

  -- Include utils
  use work.utils.all;

entity monpro_tb is
  generic (
    bit_width     : integer := 256;
    test_set_size : integer := 100;
    clock_period  : time    := 1 ns
  );
end entity monpro_tb;

architecture rtl of monpro_tb is

  -- Longest possible time to output valid (see state diagram):
  -- start states + loop states + end states
  constant worst_time_to_valid : integer := (1 + 3 * bit_width + 3);

  signal clk : std_logic;

  signal enable       : std_logic;
  signal output_valid : std_logic;

  signal operand_a : std_logic_vector(bit_width - 1 downto 0);
  signal operand_b : std_logic_vector(bit_width - 1 downto 0);
  signal modulus   : std_logic_vector(bit_width - 1 downto 0);
  signal result    : std_logic_vector(bit_width - 1 downto 0);

begin

  clock_generator(clk, clock_period);

  dut : entity work.monpro
    generic map (
      bit_width => bit_width
    )
    port map (
      clk          => clk,
      modulus      => modulus,
      operand_a    => operand_a,
      operand_b    => operand_b,
      result       => result,
      enable       => enable,
      output_valid => output_valid
    );

  test_sequencer : process is

    variable expected_result        : std_logic_vector(bit_width - 1 downto 0);
    variable test_a, test_b, test_n : std_logic_vector(bit_width - 1 downto 0);

  begin

    -- Testbench config
    set_alert_stop_limit(ERROR, 5);

    -- disable_log_msg(ID_SEQUENCER);
    -- disable_log_msg(ID_POS_ACK);

    log(ID_LOG_HDR_LARGE, "Running monpro_tb");

    for i in 0 to test_set_size - 1 loop

      log(ID_LOG_HDR, "Running test " & to_string(i));

      -- Generate random inputs

      while true loop

        test_n := random(bit_width);

        -- The modulus most be odd
        if ((unsigned(test_n) mod 2) = 1) then
          exit;
        end if;

      end loop;

      while true loop

        test_a := random(bit_width);
        test_b := random(bit_width);

        -- a and b must be less than n
        if ((unsigned(test_a) < unsigned(test_n)) and (unsigned(test_b) < unsigned(test_n))) then
          exit;
        end if;

      end loop;

      log(
          "Operand a     => " & to_string(test_a, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Operand b     => " & to_string(test_b, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Modulus       => " & to_string(test_n, HEX, AS_IS, INCL_RADIX) & "\n"
        );

      expected_result := monpro(test_a, test_b, test_n);

      -- Apply tests to DUT

      wait until falling_edge(clk);
      wait until rising_edge(clk);

      enable    <= '0';
      operand_a <= test_a;
      operand_b <= test_b;
      modulus   <= test_n;

      wait until rising_edge(clk);
      enable <= '1';

      await_value(output_valid, '1', clock_period, worst_time_to_valid * clock_period, "Awaiting output valid");

      wait until rising_edge(clk);
      enable <= '0';

      check_value(result, expected_result, "Checking result");

    end loop;

    report_alert_counters(void);

    std.env.stop;

  end process test_sequencer;

end architecture rtl;
