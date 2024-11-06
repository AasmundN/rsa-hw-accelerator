library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity rsa_core_output_control is
  generic (
    num_cores : integer := 6
  );
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : in    std_logic;

    out_reg_enable         : out   std_logic;
    out_is_last_reg_enable : out   std_logic;

    current_core_id : out   std_logic_vector(get_bit_width(num_cores) - 1 downto 0);

    -- AXI Interface
    msgout_valid : out   std_logic;
    msgout_ready : in    std_logic;

    -- Modexp control
    modexp_out_ready : out   std_logic_vector(num_cores - 1 downto 0);
    modexp_out_valid : in    std_logic_vector(num_cores - 1 downto 0)
  );
end entity rsa_core_output_control;

architecture rtl of rsa_core_output_control is

  type state_type is (
    receive_message,
    send_message
  );

  signal state, next_state : state_type;

  signal core_id_counter_reg_r : std_logic_vector(get_bit_width(num_cores) - 1 downto 0);
  signal inc_core_id_counter   : std_logic;

begin

  current_core_id <= core_id_counter_reg_r;

  main_process : process (all) is

    variable core_index : integer;

  begin

    msgout_valid           <= '0';
    modexp_out_ready       <= (others => '0');
    out_reg_enable         <= '0';
    out_is_last_reg_enable <= '0';
    inc_core_id_counter    <= '0';

    case(state) is

      when receive_message =>

        core_index := to_integer(unsigned(core_id_counter_reg_r));

        modexp_out_ready(core_index) <= '1';

        if (modexp_out_valid(core_index) = '1') then
          out_reg_enable         <= '1';
          out_is_last_reg_enable <= '1';
          inc_core_id_counter    <= '1';
          next_state             <= send_message;
        else
          next_state <= receive_message;
        end if;

      when send_message =>

        msgout_valid <= '1';

        if (msgout_ready = '1') then
          next_state <= receive_message;
        else
          next_state <= send_message;
        end if;

      when others =>

        msgout_valid           <= '0';
        modexp_out_ready       <= (others => '0');
        out_reg_enable         <= '0';
        out_is_last_reg_enable <= '0';
        inc_core_id_counter    <= '0';

    end case;

  end process main_process;

  update_state : process (clk, reset) is
  begin

    if (rising_edge(clk)) then
      if (reset = '1') then
        state <= receive_message;
      else
        state <= next_state;
      end if;
    end if;

  end process update_state;

  update_counter : process (all) is
  begin

    if (rising_edge(clk)) then
      if (reset = '1') then
        core_id_counter_reg_r <= (others => '0');
      elsif (inc_core_id_counter = '1') then
        core_id_counter_reg_r <= std_logic_vector(unsigned(core_id_counter_reg_r) + 1);

        if (unsigned(core_id_counter_reg_r) >= num_cores) then
          core_id_counter_reg_r <= (others => '0');
        end if;
      end if;
    end if;

  end process update_counter;

end architecture rtl;
