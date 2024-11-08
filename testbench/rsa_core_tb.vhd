library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;

  -- Inclue utils
  use work.utils.all;

entity rsa_core_tb is
  generic (
    bit_width     : integer := 32;
    num_cores     : integer := 8;
    test_set_size : integer := 64;
    clock_period  : time    := 1 ns
  );
end entity rsa_core_tb;

architecture func of rsa_core_tb is

  -----------------------------------------------------------------------------
  -- DUT signal interface
  -----------------------------------------------------------------------------

  signal clk   : std_logic;
  signal reset : std_logic;

  -- In/out handshake
  signal in_valid,  in_ready  : std_logic;
  signal out_ready, out_valid : std_logic;

  signal modulus  : std_logic_vector(bit_width - 1 downto 0);
  signal r_mod_n  : std_logic_vector(bit_width - 1 downto 0);
  signal r2_mod_n : std_logic_vector(bit_width - 1 downto 0);

  signal base     : std_logic_vector(bit_width - 1 downto 0);
  signal exponent : std_logic_vector(bit_width - 1 downto 0);

  signal result : std_logic_vector(bit_width - 1 downto 0);

  -----------------------------------------------------------------------------
  -- Types and utils for generating random tests
  -----------------------------------------------------------------------------

  type test_case_t is record
    msg, expected_result : std_logic_vector(bit_width - 1 downto 0);
  end record test_case_t;

  type test_cases_t is array (0 to test_set_size - 1) of test_case_t;

  type test_constants_t is record
    key_n, key_e_d, r_mod_n, r2_mod_n : std_logic_vector(bit_width - 1 downto 0);
  end record test_constants_t;

  type test_set_t is record
    cases     : test_cases_t;
    constants : test_constants_t;
  end record test_set_t;

  -- Generates a test set with random values

  function generate_tests
  return test_set_t is

    variable test_set : test_set_t;
    variable r        : std_logic_vector(bit_width - 1 downto 0);

  begin

    while true loop

      test_set.constants.key_n   := random(bit_width);
      test_set.constants.key_e_d := random(bit_width);

      -- The modulus must be odd
      if (
          (unsigned(test_set.constants.key_n) mod 2) = 1 and
          (unsigned(test_set.constants.key_e_d) < unsigned(test_set.constants.key_n))
        ) then
        exit;
      end if;

    end loop;

    -- r is 2^(n'length)
    r := std_logic_vector(shift_left(unsigned(bitscanner(test_set.constants.key_n)), 1));

    test_set.constants.r2_mod_n := modmul(r, r, test_set.constants.key_n, bit_width);
    test_set.constants.r_mod_n  := modmul(
                                          std_logic_vector(to_unsigned(1, bit_width)),
                                          r,
                                          test_set.constants.key_n,
                                          bit_width
                                        );

    for i in test_set.cases'range loop

      while true loop

        test_set.cases(i).msg := random(bit_width);

        -- msg and key must be less than n
        if (unsigned(test_set.cases(i).msg) < unsigned(test_set.constants.key_n)) then
          exit;
        end if;

      end loop;

      -- Transform inputs to Montgomery form

      test_set.cases(i).expected_result := modexp(
                                                  test_set.cases(i).msg,
                                                  test_set.constants.key_e_d,
                                                  test_set.constants.key_n
                                                );

    end loop;

    return test_set;

  end function generate_tests;

  -- Test set used during simulation

  signal test_set : test_set_t;

begin

  clock_generator(clk, clock_period);

  dut : entity work.rsa_core
    generic map (
      c_block_size => bit_width,
      num_cores    => num_cores
    )
    port map (
      clk          => clk,
      reset_n      => reset,
      key_n        => modulus,
      key_e_d      => exponent,
      r_mod_n      => r_mod_n,
      r2_mod_n     => r2_mod_n,
      msgin_data   => base,
      msgout_data  => result,
      msgin_valid  => in_valid,
      msgin_ready  => in_ready,
      msgout_ready => out_ready,
      msgout_valid => out_valid,
      msgin_last   => '0'
    );

  -----------------------------------------------------------------------------
  -- Applies the test cases to the DUT
  -----------------------------------------------------------------------------

  data_pusher : process is
  begin

    -- Testbench config
    set_alert_stop_limit(ERROR, 5);

    -- disable_log_msg(ID_SEQUENCER);
    -- disable_log_msg(ID_POS_ACK);

    log(ID_LOG_HDR, "Generating testcases");

    test_set <= generate_tests;

    wait for 1 ns;

    log(
        "Modulus       => " & to_string(test_set.constants.key_n, HEX, AS_IS, INCL_RADIX) & "\n" &
        "Key           => " & to_string(test_set.constants.key_e_d, HEX, AS_IS, INCL_RADIX) & "\n" &
        "r_mod_n       => " & to_string(test_set.constants.r_mod_n, HEX, AS_IS, INCL_RADIX) & "\n" &
        "r2_mod_n      => " & to_string(test_set.constants.r2_mod_n, HEX, AS_IS, INCL_RADIX) & "\n"
      );

    -- Apply test set constants

    modulus  <= test_set.constants.key_n;
    exponent <= test_set.constants.key_e_d;
    r_mod_n  <= test_set.constants.r_mod_n;
    r2_mod_n <= test_set.constants.r2_mod_n;

    -- Apply reset

    reset <= '1';

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    reset <= '0';

    -- Start main test sequence

    for i in 0 to test_set_size - 1 loop

      log(ID_LOG_HDR, "Applying testcase " & to_string(i));

      log(
          "Base          => " & to_string(test_set.cases(i).msg, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Expected out  => " & to_string(test_set.cases(i).expected_result, HEX, AS_IS, INCL_RADIX) & "\n"
        );

      -- Apply test to DUT

      base <= test_set.cases(i).msg;

      -- Perform input handshake

      in_valid <= '1';

      wait until rising_edge(clk);

      if (in_ready = '0') then
        wait until rising_edge(in_ready);
        wait until rising_edge(clk);
      end if;

    end loop;

    wait;

  end process data_pusher;

  -----------------------------------------------------------------------------
  -- Retrieves and verifies the results from the DUT
  -----------------------------------------------------------------------------

  data_puller : process is
  begin

    out_ready <= '0';

    wait for clock_period;

    for i in 0 to test_set_size - 1 loop

      out_ready <= '1';

      if (out_valid = '0') then
        wait until rising_edge(out_valid);
      end if;

      wait until rising_edge(clk);

      check_value(result, test_set.cases(i).expected_result, "Testcase " & to_string(i));

      wait until rising_edge(clk);

    end loop;

    report_alert_counters(void);

    std.env.finish;

  end process data_puller;

end architecture func;
