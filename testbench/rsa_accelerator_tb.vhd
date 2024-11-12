-- *****************************************************************************
-- Name:     rsa_accelerator_tb.vhd
-- Project:  TFE4141 Term project 2018
-- Created:  03.10.04, 08.11.18
-- Author:   Øystein Gjermundnes
-- Purpose:  A small testbench for the rsa_core
-- *****************************************************************************

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_real.all;
  use ieee.numeric_std.all;

library std;
  use std.textio.all;

entity rsa_accelerator_tb is
end entity rsa_accelerator_tb;

architecture struct of rsa_accelerator_tb is

  -----------------------------------------------------------------------------
  -- Constant declarations
  -----------------------------------------------------------------------------
  constant c_block_size : integer := 256;
  constant num_cores    : integer := 4;

  -- RENAME this constant to "long_test" for more comprehensive tests
  -- "short_test" for shorter tests
  constant c_testcase_folder : string := "../rsa_tests/short_test";

  -----------------------------------------------------------------------------
  -- Clocks and reset
  -----------------------------------------------------------------------------
  signal clk     : std_logic;
  signal reset_n : std_logic;

  -----------------------------------------------------------------------------
  -- Slave msgin interface
  -----------------------------------------------------------------------------
  -- Message that will be sent out is valid
  signal msgin_valid : std_logic;
  -- Slave ready to accept a new message
  signal msgin_ready : std_logic;
  -- Message that will be sent out of the rsa_msgin module
  signal msgin_data : std_logic_vector(c_block_size - 1 downto 0);
  -- Indicates boundary of last packet
  signal msgin_last : std_logic;

  -----------------------------------------------------------------------------
  -- Master msgout interface
  -----------------------------------------------------------------------------
  -- Message that will be sent out is valid
  signal msgout_valid : std_logic;
  -- Slave ready to accept a new message
  signal msgout_ready : std_logic;
  -- Message that will be sent out of the rsa_msgin module
  signal msgout_data : std_logic_vector(c_block_size - 1 downto 0);
  -- Indicates boundary of last packet
  signal msgout_last : std_logic;

  -----------------------------------------------------------------------------
  -- Interface to the register block
  -----------------------------------------------------------------------------
  signal key_e_d    : std_logic_vector(c_block_size - 1 downto 0);
  signal key_n      : std_logic_vector(c_block_size - 1 downto 0);
  signal r_mod_n    : std_logic_vector(c_block_size - 1 downto 0);
  signal r2_mod_n   : std_logic_vector(c_block_size - 1 downto 0);
  signal rsa_status : std_logic_vector(31 downto 0);

  -----------------------------------------------------------------------------
  -- Testcases
  -- The folder with the tests (rsa_tests), must be placed in the working
  -- directory.
  -- The testcases are the same as the ones that will run on the PYNQ platform.
  -- Simulation of the largest testcases will take a lot of time.
  -----------------------------------------------------------------------------
  file tc_inp : text;
  file tc_otp : text;

  -----------------------------------------------------------------------------
  -- Procedure for opening a file with input vectors
  -----------------------------------------------------------------------------

  procedure open_tc_inp (
    testcase_id : in integer
  ) is
  begin

    if (testcase_id = 0) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_pt0_in.txt", read_mode);
    elsif (testcase_id = 1) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_pt1_in.txt", read_mode);
    elsif (testcase_id = 2) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_pt2_in.txt", read_mode);
    elsif (testcase_id = 3) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_ct3_in.txt", read_mode);
    elsif (testcase_id = 4) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_ct4_in.txt", read_mode);
    elsif (testcase_id = 5) then
      file_open(tc_inp, C_TESTCASE_FOLDER & ".inp_messages.hex_ct5_in.txt", read_mode);
    end if;

  end procedure open_tc_inp;

  -----------------------------------------------------------------------------
  -- Procedure for opening a file with output vectors
  -----------------------------------------------------------------------------

  procedure open_tc_otp (
    testcase_id : in integer
  ) is
  begin

    if (testcase_id = 0) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_ct0_out.txt", read_mode);
    elsif (testcase_id = 1) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_ct1_out.txt", read_mode);
    elsif (testcase_id = 2) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_ct2_out.txt", read_mode);
    elsif (testcase_id = 3) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_pt3_out.txt", read_mode);
    elsif (testcase_id = 4) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_pt4_out.txt", read_mode);
    elsif (testcase_id = 5) then
      file_open(tc_otp, C_TESTCASE_FOLDER & ".otp_messages.hex_pt5_out.txt", read_mode);
    end if;

  end procedure open_tc_otp;

  -----------------------------------------------------------------------------
  -- Function for converting from hex strings to std_logic_vector.
  -----------------------------------------------------------------------------

  function str_to_stdvec (
    inp: string
  ) return std_logic_vector is

    variable temp  : std_logic_vector(4 * inp'length-1 downto 0) := (others => 'X');
    variable temp1 : std_logic_vector(3 downto 0);

  begin

    for i in inp'range loop

      case inp(i) is

        when '0' =>

          temp1 := x"0";

        when '1' =>

          temp1 := x"1";

        when '2' =>

          temp1 := x"2";

        when '3' =>

          temp1 := x"3";

        when '4' =>

          temp1 := x"4";

        when '5' =>

          temp1 := x"5";

        when '6' =>

          temp1 := x"6";

        when '7' =>

          temp1 := x"7";

        when '8' =>

          temp1 := x"8";

        when '9' =>

          temp1 := x"9";

        when 'A'|'a' =>

          temp1 := x"A";

        when 'B'|'b' =>

          temp1 := x"B";

        when 'C'|'c' =>

          temp1 := x"C";

        when 'D'|'d' =>

          temp1 := x"D";

        when 'E'|'e' =>

          temp1 := x"E";

        when 'F'|'f' =>

          temp1 := x"F";

        when others =>

          temp1 := "XXXX";

      end case;

      temp(4 * (i - 1) + 3 downto 4 * (i - 1)) := temp1;

    end loop;

    return temp;

  end function str_to_stdvec;

  -----------------------------------------------------------------------------
  -- Function for converting from std_logic_vector to a string.
  -----------------------------------------------------------------------------

  function stdvec_to_string (
    a: std_logic_vector
  ) return string is

    variable b      : string (a'length / 4 downto 1) := (others => NUL);
    variable nibble : std_logic_vector(3 downto 0);

  begin

    for i in b'length downto 1 loop

      nibble := a(i * 4 - 1 downto (i - 1) * 4);

      case nibble is

        when "0000" =>

          b(i) := '0';

        when "0001" =>

          b(i) := '1';

        when "0010" =>

          b(i) := '2';

        when "0011" =>

          b(i) := '3';

        when "0100" =>

          b(i) := '4';

        when "0101" =>

          b(i) := '5';

        when "0110" =>

          b(i) := '6';

        when "0111" =>

          b(i) := '7';

        when "1000" =>

          b(i) := '8';

        when "1001" =>

          b(i) := '9';

        when "1010" =>

          b(i) := 'A';

        when "1011" =>

          b(i) := 'B';

        when "1100" =>

          b(i) := 'C';

        when "1101" =>

          b(i) := 'D';

        when "1110" =>

          b(i) := 'E';

        when "1111" =>

          b(i) := 'F';

        when others =>

          b(i) := 'X';

      end case;

    end loop;

    return b;

  end function stdvec_to_string;

  -----------------------------------------------------------------------------
  -- Procedure for reading keys and command
  --
  -- The file with the testcase has a section with the keys first followed by
  -- the messages that will be encrypted/decrypted.
  --
  -- Example testcase file without the messages:
  --
  --   # KEY N
  --   99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d
  --   # KEY E
  --   0000000000000000000000000000000000000000000000000000000000010001
  --   # KEY D
  --   0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9
  --   # KEY R_MOD_N
  --   0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9
  --   # KEY R2_MOD_N
  --   0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9
  --   # COMMAND
  --   1
  --
  -----------------------------------------------------------------------------

  procedure read_keys_and_command (
    signal kn      : out std_logic_vector(c_block_size - 1 downto 0);
    signal ked     : out std_logic_vector(c_block_size - 1 downto 0);
    signal krmodn  : out std_logic_vector(c_block_size - 1 downto 0);
    signal kr2modn : out std_logic_vector(c_block_size - 1 downto 0)
  ) is

    variable line_from_file : line;
    variable s1             : string(1 downto 1);
    variable s64            : string(C_BLOCK_SIZE / 4 downto 1);
    variable command        : std_logic;
    variable e              : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    variable d              : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    variable n              : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    variable rmodn          : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);
    variable r2modn         : std_logic_vector(C_BLOCK_SIZE - 1 downto 0);

  begin

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Read KEY N
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    n := str_to_stdvec(s64);

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Read KEY E
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    e := str_to_stdvec(s64);

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Read KEY D
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    d := str_to_stdvec(s64);

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Read KEY R_MOD_N
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    rmodn := str_to_stdvec(s64);

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Read KEY R2_MOD_N
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    r2modn := str_to_stdvec(s64);

    -- Read comment
    readline(tc_inp, line_from_file);
    -- Command (Encrypt/Decrypt)
    -- 1: Encrypt
    -- 0: Decrypt
    readline(tc_inp, line_from_file);
    read(line_from_file, s1);
    command := str_to_stdvec(s1)(0);

    -- Read empty line
    readline(tc_inp, line_from_file);

    -- Encryption key selected
    if (command = '1') then
      ked <= e;
    -- Decryption key selected
    else
      ked <= d;
    end if;

    kn      <= n;
    krmodn  <= rmodn;
    kr2modn <= r2modn;

  end procedure read_keys_and_command;

  -----------------------------------------------------------------------------
  -- Procedure for reading input messages
  -----------------------------------------------------------------------------

  procedure read_input_message (
    variable input_message : out std_logic_vector(c_block_size - 1 downto 0)
  ) is

    variable line_from_file : line;
    variable s64            : string(C_BLOCK_SIZE / 4 downto 1);

  begin

    -- Read input message
    readline(tc_inp, line_from_file);
    read(line_from_file, s64);
    input_message := str_to_stdvec(s64);

  end procedure read_input_message;

  -----------------------------------------------------------------------------
  -- Procedure for reading output messages
  -----------------------------------------------------------------------------

  procedure read_output_message (
    variable output_message : out std_logic_vector(c_block_size - 1 downto 0)
  ) is

    variable line_from_file : line;
    variable s64            : string(C_BLOCK_SIZE / 4 downto 1);

  begin

    -- Read output message
    readline(tc_otp, line_from_file);
    read(line_from_file, s64);
    output_message := str_to_stdvec(s64);

  end procedure read_output_message;

  -----------------------------------------------------------------------------
  -- Internal signals
  -----------------------------------------------------------------------------

  -- Testcase control states

  type tc_ctrl_state_t is (e_tc_start_tc, e_tc_run_tc, e_tc_wait_completed, e_tc_completed, e_tc_all_tests_completed);

  signal tc_ctrl_state                : tc_ctrl_state_t;
  signal all_input_messages_sent      : std_logic;
  signal all_output_messages_received : std_logic;
  signal test_case_id                 : integer;
  signal start_tc                     : std_logic;

  -- Msgin control states

  type msgin_state_t is (e_msgin_idle, e_msgin_send, e_msgin_completed);

  signal msgin_state   : msgin_state_t;
  signal msgin_counter : unsigned(15 downto 0);

  -- Msgout control states

  type msgout_state_t is (e_msgout_idle, e_msgout_receive, e_msgout_completed);

  signal msgout_state   : msgout_state_t;
  signal msgout_counter : unsigned(15 downto 0);

  signal msgout_valid_prev : std_logic;
  signal msgout_ready_prev : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Clock and reset generation
  -----------------------------------------------------------------------------
  -- Generates a 50MHz clk
  clk_gen : process is
  begin

    clk <= '1';
    wait for 6 ns;
    clk <= '0';
    wait for 6 ns;

  end process;

  -- reset_n generator
  reset_gen : process is
  begin

    reset_n <= '0';
    wait for 20 ns;
    reset_n <= '1';
    wait;

  end process;

  -----------------------------------------------------------------------------
  -- testcase_control
  -- Process that sets up the correct keys and initializes the testcases.
  -----------------------------------------------------------------------------
  testcase_control : process (clk, reset_n) is
  begin

    if (reset_n = '0') then
      tc_ctrl_state <= e_tc_start_tc;
      key_n         <= (others => '0');
      key_e_d       <= (others => '0');
      r_mod_n       <= (others => '0');
      r2_mod_n      <= (others => '0');
      test_case_id  <= 0;
      start_tc      <= '0';
    elsif (clk'event and clk = '1') then
      -- Default values
      start_tc <= '0';

      case tc_ctrl_state is

        -- Start a new test case
        when e_tc_start_tc =>

          assert true;
          report "********************************************************************************";
          report "STARTING NEW TESTCASE";
          report "********************************************************************************";

          tc_ctrl_state <= e_tc_run_tc;
          open_tc_inp(test_case_id);
          open_tc_otp(test_case_id);
          read_keys_and_command(key_n, key_e_d, r_mod_n, r2_mod_n);

          start_tc <= '1';

        -- Run the testcase
        when e_tc_run_tc =>

          if (all_input_messages_sent = '1') then
            tc_ctrl_state <= e_tc_wait_completed;
          end if;

        -- Wait for all the output messages to arrive
        when e_tc_wait_completed =>

          if (all_output_messages_received = '1') then
            tc_ctrl_state <= e_tc_completed;
          end if;

        -- Testcase is finished
        when e_tc_completed =>

          if (test_case_id >= 5) then
            tc_ctrl_state <= e_tc_all_tests_completed;
          else
            tc_ctrl_state <= e_tc_start_tc;
            test_case_id  <= test_case_id + 1;
          end if;
          file_close(tc_inp);
          file_close(tc_otp);

        -- All tests have been completed
        when others => -- e_TC_ALL_TESTS_COMPLETED =>

          assert true;
          report "********************************************************************************";
          report "ALL TESTS FINISHED SUCCESSFULLY";
          report "********************************************************************************";
          report "ENDING SIMULATION..."
            severity Failure;

      end case;

    end if;

  end process;

  -----------------------------------------------------------------------------
  -- msgin_bfm
  -- Process that sends messages into the rsa_core
  -----------------------------------------------------------------------------
  msgin_bfm : process (clk, reset_n) is

    variable msgin_valid_ready : std_logic_vector(1 downto 0);
    variable seed1, seed2      : positive; -- seed values for random generator
    variable rand              : real;     -- random real-number value in range 0 to 1.0
    variable wait_one_cycle    : integer;  -- Used for inserting delays between messages.
    variable input_message     : std_logic_vector(c_block_size - 1 downto 0);

  begin

    if (reset_n = '0') then
      -- Drive the inputs of rsa_core to default values
      msgin_valid   <= '0';
      msgin_data    <= (others => '0');
      msgin_last    <= '0';
      msgin_counter <= (others => '0');
    elsif (clk'event and clk = '1') then
      -- Default values
      all_input_messages_sent <= '0';

      case msgin_state is

        -- Wait until a new test is started
        when e_msgin_idle =>

          if (start_tc = '1') then
            msgin_state <= e_msgin_send;
          end if;

        -- Send messages
        when e_msgin_send =>

          msgin_valid_ready := msgin_valid & msgin_ready;

          case msgin_valid_ready is

            -- Send a new message if possible
            when "00"|"01"|"11" =>

              -- Generate a random number. It will be used for
              -- deciding whether or not to insert delays between messages
              uniform(seed1, seed2, rand);
              wait_one_cycle := integer(rand);

              -- Check if there are more messages to send
              if (endfile(tc_inp)) then
                msgin_state             <= e_msgin_completed;
                all_input_messages_sent <= '1';
                msgin_valid             <= '0';
                msgin_data              <= (others => '0');
                msgin_last              <= '0';

              -- Wait a cycle before sending any new messages
              elsif (wait_one_cycle = 0) then
                msgin_valid <= '0';
                msgin_data  <= (others => '0');
                msgin_last  <= '0';

              -- Send a new message
              -- The last signal is set now and then.
              else
                msgin_valid   <= '1';
                read_input_message(input_message);
                msgin_data    <= input_message;
                report "DRIVE NEW MSGIN_DATA[" & stdvec_to_string(std_logic_vector(msgin_counter)) & "] " & "RTL: " & stdvec_to_string(input_message);
                msgin_last    <= msgin_counter(1);
                msgin_counter <= msgin_counter + 1;
              end if;

            -- We are currently trying to send a message,
            -- but it has not yet been accepted.
            when others =>                                                                                                                             -- "10" =>

          end case;

        -- All messages have been sent
        when others =>                                                                                                                                 -- e_MSGIN_COMPLETED =>

          msgin_state <= e_msgin_idle;

      end case;

    end if;

  end process;

  -----------------------------------------------------------------------------
  -- msgout_bfm
  -- Process that receives messages from the rsa_core
  -----------------------------------------------------------------------------
  msgout_bfm : process (clk, reset_n) is

    variable msgout_valid_ready   : std_logic_vector(1 downto 0);
    variable seed1, seed2         : positive; -- seed values for random generator
    variable rand                 : real;     -- random real-number value in range 0 to 1.0
    variable wait_one_cycle       : integer;  -- Used for inserting delays between messages.
    variable expected_msgout_data : std_logic_vector(c_block_size - 1 downto 0);

  begin

    if (reset_n = '0') then
      -- Drive the inputs of rsa_core to default values
      msgout_ready   <= '0';
      msgout_counter <= (others => '0');
    elsif (clk'event and clk = '1') then
      -- Default values
      all_output_messages_received <= '0';
      msgout_valid_prev            <= msgout_valid;
      msgout_ready_prev            <= msgout_ready;

      case msgout_state is

        -- Wait until a new test is started
        when e_msgout_idle =>

          if (start_tc = '1') then
            msgout_state <= e_msgout_receive;
          end if;

        -- Send messages
        when e_msgout_receive =>

          -- Generate a random number. It will be used for
          -- deciding whether or not to drive the msgout_ready signal low and
          -- block incoming messages.
          uniform(seed1, seed2, rand);
          wait_one_cycle := integer(rand);
          if (wait_one_cycle = 0) then
            msgout_ready <= '0';
          else
            msgout_ready <= '1';
          end if;

          if ((msgout_valid_prev = '1') and (msgout_valid = '0') and (msgout_ready_prev = '0')) then
            assert true;
            report "Error in AXIS-Handshake. msgout_valid goes high to low without msgout_ready high."
              severity Failure;
          end if;

          msgout_valid_ready := msgout_valid & msgout_ready;

          case msgout_valid_ready is

            -- Check that the result is correct when a message is
            -- received
            when "11" =>

              msgout_counter <= msgout_counter + 1;
              read_output_message(expected_msgout_data);
              assert true;
              report "COMPARE MSGOUT_DATA[" & stdvec_to_string(std_logic_vector(msgout_counter)) & "] " & "RTL: " & stdvec_to_string(msgout_data) & "   EXPECTED: " & stdvec_to_string(expected_msgout_data);
              assert expected_msgout_data = msgout_data
                report "Output message differs from the expected result"
                severity Failure;
              assert msgout_counter(1) = msgout_last
                report "msgin_last/msgout_last mismatch"
                severity Failure;

            -- Receive a new message now and then
            when others =>                                                                                                                                                                                    -- "00"|"01"|"10" =>

              -- Check if there are more messages to send
              if (endfile(tc_otp)) then
                msgout_state                 <= e_msgout_completed;
                all_output_messages_received <= '1';
              end if;

          end case;

        -- All messages have been sent
        when others =>                                                                                                                                                                                        -- e_MSGOUT_COMPLETED =>

          msgout_state <= e_msgout_idle;

      end case;

    end if;

  end process;

  ---------------------------------------------------------------------------------
  -- Instantiate the design under test (DUT)
  ---------------------------------------------------------------------------------
  u_rsa_core : entity work.rsa_core
    generic map (
      c_block_size => c_block_size,
      num_cores    => num_cores
    )
    port map (
      -----------------------------------------------------------------------------
      -- Clocks and reset
      -----------------------------------------------------------------------------
      clk     => clk,
      reset_n => reset_n,

      -----------------------------------------------------------------------------
      -- Slave msgin interface
      -----------------------------------------------------------------------------
      msgin_valid => msgin_valid,
      msgin_ready => msgin_ready,
      msgin_data  => msgin_data,
      msgin_last  => msgin_last,

      -----------------------------------------------------------------------------
      -- Master msgout interface
      -----------------------------------------------------------------------------
      msgout_valid => msgout_valid,
      msgout_ready => msgout_ready,
      msgout_data  => msgout_data,
      msgout_last  => msgout_last,

      -----------------------------------------------------------------------------
      -- Interface to the register block
      -----------------------------------------------------------------------------
      key_e_d    => key_e_d,
      key_n      => key_n,
      r_mod_n    => r_mod_n,
      r2_mod_n   => r2_mod_n,
      rsa_status => rsa_status

    );

end architecture struct;

