library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity modmul_control is
  port (
    -- Clock and reset
    clk   : in    std_logic;
    reset : out   std_logic; -- Used to reset datapath

    -- Enable module
    enable : in    std_logic;

    -- Flags
    alu_less_than : in    std_logic;
    a_is_last     : in    std_logic;

    -- ALU control signals
    alu_opcode   : out   alu_opcode_t;
    alu_a_select : out   std_logic;
    alu_b_select : out   std_logic;

    -- Register control
    output_valid           : out   std_logic;
    out_reg_enable         : out   std_logic;
    shift_reg_enable       : out   std_logic;
    shift_reg_shift_enable : out   std_logic
  );
end entity modmul_control;

architecture rtl of modmul_control is

  type state_type is (
    idle, start,
    add_b, comp,
    save, shift,
    valid
  );

  type alu_a_operand is (out_reg_shifted, out_reg);

  type alu_b_operand is (b_operand, modulus_operand);

  -- Conversion functions for operands

  function to_logic (
    val : alu_a_operand
  ) return std_logic is
  begin

    case val is

      when out_reg =>

        return '0';

      when out_reg_shifted =>

        return '1';

    end case;

  end function to_logic;

  function to_logic (
    val : alu_b_operand
  ) return std_logic is
  begin

    case val is

      when b_operand =>

        return '0';

      when modulus_operand =>

        return '1';

    end case;

  end function to_logic;

  -- Internal registers
  signal i_counter_r                                 : std_logic_vector(1 downto 0);
  signal i_counter_increment_enable, i_counter_reset : std_logic;

  -- State signals
  signal state,                      state_next : state_type;

begin

  main_process : process (all) is
  begin

    reset <= '0';

    -- Default values for ALU control signals
    alu_opcode   <= pass;
    alu_a_select <= to_logic(out_reg);
    alu_b_select <= to_logic(b_operand);

    -- Default values for Register control signals
    output_valid               <= '0';
    out_reg_enable             <= '0';
    shift_reg_enable           <= '0';
    shift_reg_shift_enable     <= '0';
    i_counter_increment_enable <= '0';
    i_counter_reset            <= '0';

    state_next <= idle;

    case(state) is

      when idle =>

        if (enable = '1') then
          state_next <= start;
        else
          state_next <= idle;
        end if;

      when start =>

        shift_reg_enable <= '1';
        reset            <= '1';

        if (enable = '1') then
          state_next <= add_b;
        else
          state_next <= idle;
        end if;

      when add_b =>

        alu_opcode     <= add;
        out_reg_enable <= '1';
        alu_a_select   <= to_logic(out_reg_shifted);
        alu_b_select   <= to_logic(b_operand);

        if (enable = '1') then
          state_next <= comp;
        else
          state_next <= idle;
        end if;

      when comp =>

        alu_opcode   <= sub;
        alu_a_select <= to_logic(out_reg);
        alu_b_select <= to_logic(modulus_operand);

        if (enable = '1') then
          if (alu_less_than = '1') then
            state_next <= shift;
          else
            state_next <= save;
          end if;
        else
          state_next <= idle;
        end if;

      when save =>
      out_reg_enable <= '1';
      i_counter_increment_enable <= '1';

      if (enable = '1') then
        if (to_integer(unsigned(i_counter_r)) < 3) then
          state_next <= comp;
        else
          state_next <= shift;
        end if;
      else
        state_next <= idle;
      end if;

      when shift =>
      alu_opcode <= add;
      shift_reg_shift_enable <= '1';
      alu_a_select <= to_logic(out_reg_shifted);
      alu_b_select <= to_logic(b_operand);
      i_counter_reset <= '1';

      if (enable = '1') then
        if (a_is_last = '1') then
          state_next <= valid;
          else
          state_next <= add_b;
        end if;
      else
        state_next <= idle;
      end if;

    end case;

  end process main_process;

end architecture rtl;
