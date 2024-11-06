library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- Utils
  use work.utils.all;

entity rsa_core_input_control is
  generic (
    num_cores : integer := 6
  );
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : in    std_logic;

    in_reg_enable         : out   std_logic;
    in_is_last_reg_enable : out   std_logic;

    -- AXI Interface
    msgin_valid : in    std_logic;
    msgin_ready : out   std_logic;

    -- Modexp control
    modexp_in_ready : in    std_logic_vector(num_cores - 1 downto 0);
    modexp_in_valid : out   std_logic_vector(num_cores - 1 downto 0)
  );
end entity rsa_core_input_control;

architecture rtl of rsa_core_input_control is

  type state_type is (
    receive_message,
    assign_message
  );

  signal state, next_state : state_type;

  signal core_id_counter_reg_r : std_logic_vector(get_bit_width(num_cores) - 1 downto 0);
  signal inc_core_id_counter   : std_logic;

begin

  main_process : process (all) is

    variable core_index : integer;

  begin

    msgin_ready           <= '0';
    modexp_in_valid       <= (others => '0');
    in_reg_enable         <= '0';
    in_is_last_reg_enable <= '0';
    inc_core_id_counter   <= '0';

    case(state) is

      when receive_message =>

        msgin_ready <= '1';

        if (msgin_valid = '1') then
          in_reg_enable         <= '1';
          in_is_last_reg_enable <= '1';
          next_state            <= assign_message;
        else
          next_state <= receive_message;
        end if;

      when assign_message =>

        core_index := to_integer(unsigned(core_id_counter_reg_r));

        modexp_in_valid(core_index) <= '1';

        if (modexp_in_ready(core_index) = '1') then
          inc_core_id_counter <= '1';
          next_state          <= receive_message;
        else
          next_state <= assign_message;
        end if;

      when others =>

        msgin_ready           <= '0';
        modexp_in_valid       <= (others => '0');
        in_reg_enable         <= '0';
        in_is_last_reg_enable <= '0';
        inc_core_id_counter   <= '0';

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
