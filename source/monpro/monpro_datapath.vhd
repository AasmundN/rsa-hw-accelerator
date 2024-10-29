library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- include utils package
  use work.utils.all;

entity monpro_datapath is
  generic (
    bit_width : integer := 256
  );
  port (
    -----------------------------------------------------------------------------
    -- Clock and reset
    -----------------------------------------------------------------------------
    clk   : in    std_logic;
    reset : in    std_logic;

    -----------------------------------------------------------------------------
    -- ALU interface
    -----------------------------------------------------------------------------
    alu_opcode    : in    alu_opcode_t;
    alu_a_select     : in    std_logic;
    alu_b_select   : in    std_logic;
    alu_less_than : out   std_logic;

    -----------------------------------------------------------------------------
    -- Internal register control signals
    -----------------------------------------------------------------------------
    outreg_enable         : in    std_logic;
    shiftreg_enable       : in    std_logic;
    shiftreg_shift_enable : in    std_logic;

    -----------------------------------------------------------------------------
    -- Main inputs and outputs
    -----------------------------------------------------------------------------
    modulus   : in    std_logic_vector(bit_width - 1 downto 0);
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);
    result    : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- u(0) xor (a(i) and b(0))
    -----------------------------------------------------------------------------
    is_odd : out   std_logic
  );
end entity monpro_datapath;

architecture rtl of monpro_datapath is

  -- b anded with ith bit of a
  signal and_b_a : std_logic_vector(bit_width - 1 downto 0);

  -- Internal registers
  -- Intermediary result has size bit_width+1
  signal outreg_r   : std_logic_vector(bit_width downto 0);
  signal shiftreg_r : std_logic_vector(bit_width - 1 downto 0);

  -- Output from bit shifter
  signal outreg_right_shifted : std_logic_vector(bit_width downto 0);

  -- ALU inputs and outputs
  signal alu_a      : std_logic_vector(bit_width downto 0);
  signal alu_b      : std_logic_vector(bit_width downto 0);
  signal alu_result : std_logic_vector(bit_width downto 0);

begin

  result <= outreg_r(bit_width - 1 downto 0);
  is_odd <= outreg_r(0) xor (operand_b(0) and shiftreg_r(0));

  alu : entity work.alu(rtl)
    generic map (
      bit_width => bit_width + 1
    )
    port map (
      operand_a => alu_a,
      operand_b => alu_b,
      result    => alu_result,
      opcode    => alu_opcode,
      less_than => alu_less_than
    );

  alu_a_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width + 1
    )
    port map (
      a0  => outreg_r,
      a1  => outreg_right_shifted,
      b   => alu_a,
      sel => alu_a_select
    );

  -- shiftreg_r(0) and operand_b are different sizes, might be sussy
  and_b_a <= operand_b and shiftreg_r(0);

  alu_b_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width + 1
    )
    port map (
      a0  => '0' & modulus,
      a1  => '0' & and_b_a,
      b   => alu_b,
      sel => alu_b_select
    );

  -- Right shift one bit
  bit_shifter : process (outreg_r) is
  begin

    outreg_right_shifted <= '0' & outreg_r(bit_width downto 1);

  end process bit_shifter;

  outreg : process (clk, reset, outreg_enable, alu_result) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        outreg_r <= (others => '0');
      elsif (outreg_enable = '1') then
        outreg_r <= alu_result;
      end if;
    end if;

  end process outreg;

  shiftreg : process (clk, reset, shiftreg_enable, shiftreg_shift_enable, alu_result) is
  begin

    if rising_edge(clk) then
      -- Reset register
      if (reset = '1') then
        shiftreg_r <= (others => '0');
      -- Latch register input
      elsif (shiftreg_enable = '1') then
        shiftreg_r <= operand_a;
      -- Shift register content
      elsif (shiftreg_shift_enable = '1') then
        shiftreg_r <= '0' & shiftreg_r(bit_width - 1 downto 1);
      end if;
    end if;

  end process shiftreg;

end architecture rtl;
