library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


library uvvm_util;
  context uvvm_util.uvvm_util_context;

  -- Inclue utils
  use work.utils.all;

entity modexp_tb is
  generic (
    bit_width     : integer := 32;
    test_set_size : integer := 5;
    clock_period  : time    := 1 ns
  );
end entity modexp_tb;

architecture func of modexp_tb is

  -- Longest possible time to output valid (see state diagrams):
  -- start states + loop states + end states
  constant worst_time_to_monpro_valid : integer := (2 * bit_width + 2);
  constant worst_time_to_valid        : integer := bit_width +
                                                   (2 * worst_time_to_monpro_valid + 1) * bit_width +
                                                   worst_time_to_monpro_valid + 1;

  signal clk_counter : natural;

  signal clk   : std_logic;
  signal reset : std_logic;

  signal modulus       : std_logic_vector(bit_width - 1 downto 0);
  signal operand_m : std_logic_vector(bit_width - 1 downto 0);
  signal operand_x_bar : std_logic_vector(bit_width - 1 downto 0);
  signal operand_e     : std_logic_vector(bit_width - 1 downto 0);
  signal operand_r_sq_modn : std_logic_vector(bit_width - 1 downto 0);

  signal result : std_logic_vector(bit_width - 1 downto 0);

  -- In/out handshake
  signal in_valid,  in_ready  : std_logic;
  signal out_ready, out_valid : std_logic;

begin

  clock_generator(clk, clk_counter, clock_period);

  dut : entity work.modexp
    generic map (
      bit_width => bit_width
    )
    port map (
      clk           => clk,
      reset         => reset,
      modulus       => modulus,
      operand_m => operand_m,
      operand_x_bar => operand_x_bar,
      operand_e     => operand_e,
      operand_r_sq_modn => operand_r_sq_modn,
      result        => result,
      in_valid      => in_valid,
      in_ready      => in_ready,
      out_ready     => out_ready,
      out_valid     => out_valid
    );

  test_sequencer : process is

    variable expected_result : std_logic_vector(bit_width - 1 downto 0);

    variable test_m, test_e, test_n : std_logic_vector(bit_width downto 0);
    variable test_x_bar : std_logic_vector(bit_width downto 0);
    variable test_r, test_r_sq_modn            : std_logic_vector(bit_width downto 0);
    
    variable clk_count_at_start : natural;

  begin

    -- Testbench config
    set_alert_stop_limit(ERROR, 5);

    -- disable_log_msg(ID_SEQUENCER);
    -- disable_log_msg(ID_POS_ACK);

    reset <= '1';

    wait until falling_edge(clk);
    wait until rising_edge(clk);

    reset <= '0';

    for i in 0 to test_set_size - 1 loop

      log(ID_LOG_HDR, "Running test " & to_string(i));

      while true loop

        test_n := '0' & random(bit_width);

        -- The modulus must be odd
        if ((unsigned(test_n) mod 2) = 1) then
          exit;
        end if;

      end loop;

      while true loop

        test_m := '0' & random(bit_width);
        test_e := '0' & random(bit_width);

        -- m and e must be less than n
        if ((unsigned(test_m) < unsigned(test_n)) and (unsigned(test_e) < unsigned(test_n))) then
          exit;
        end if;

      end loop;

      -- Transform inputs to Montgomery form

      -- r is 2^(n'length)
      test_r := std_logic_vector(shift_left(unsigned(bitscanner(test_n)), 1));
      test_r_sq_modn := std_logic_vector(resize((unsigned(test_r) * unsigned(test_r)) mod unsigned(modulus), bit_width + 1));

      test_x_bar := modmul(std_logic_vector(to_unsigned(1, bit_width + 1)), test_r, test_n, bit_width + 1);

      expected_result := modexp(test_m, test_e, test_n)(expected_result'range);

      log(
          "Base          => " & to_string(test_m, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Exponent      => " & to_string(test_e, HEX, AS_IS, INCL_RADIX) & "\n" &
          "Modulus       => " & to_string(test_n, HEX, AS_IS, INCL_RADIX) & "\n\n" &
          
          "_x            => " & to_string(test_x_bar, HEX, AS_IS, INCL_RADIX) & "\n"
        );

      clk_count_at_start := clk_counter;

      -- Apply tests to DUT

      operand_m <= test_m(operand_m'range);
      operand_x_bar <= test_x_bar(operand_x_bar'range);
      operand_e     <= test_e(operand_e'range);
      operand_r_sq_modn <= test_r_sq_modn(operand_r_sq_modn'range);
      modulus       <= test_n(modulus'range);

      -- Perform input handshake

      in_valid <= '1';

      if (in_ready = '0') then
        wait until rising_edge(in_ready);
      end if;

      wait until falling_edge(clk);
      wait until rising_edge(clk);

      in_valid <= '0';

      -- Await completion of calculation

      out_ready <= '1';

      await_value(out_valid, '1', clock_period, worst_time_to_valid * clock_period, "Awaiting output valid");

      wait until rising_edge(clk);

      check_value(result, expected_result, "Checking result");

      out_ready <= '0';

      log("\nClock cycle count: " & to_string(clk_counter - clk_count_at_start));

    end loop;

    report_alert_counters(void);

    std.env.stop;

  end process test_sequencer;

end architecture func;
