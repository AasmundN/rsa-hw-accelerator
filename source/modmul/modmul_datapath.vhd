library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.utils.all;

entity modmul_datapath is
  generic (
    bit_width : integer := 256
  );
  port (
    -- misc
    clk   : in    std_logic;
    reset : in    std_logic;

    -- main input and outputs
    modulus   : in    std_logic_vector(bit_width - 1 downto 0);
    operand_a : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b : in    std_logic_vector(bit_width - 1 downto 0);
    result    : out   std_logic_vector(bit_width - 1 downto 0);

    -- control inputs
    out_reg_enable         : in    std_logic;
    shift_reg_enable       : in    std_logic;
    shift_reg_shift_enable : in    std_logic;

    alu_opcode   : in    alu_opcode_t;
    alu_a_select : in    std_logic;
    alu_b_select : in    std_logic;

    -- control outputs
    operand_a_last_bit : out   std_logic;
    alu_less_than      : out   std_logic
  );
end entity modmul_datapath;

architecture rtl of modmul_datapath is

  -- internal registers
  signal a_reg_r              : std_logic_vector(bit_width - 1 downto 0);
  signal a_last_reg_r         : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_r            : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_left_shifted : std_logic_vector(bit_width - 1 downto 0); -- register on input-side A of alu

  signal bit_scanner_out : std_logic_vector(bit_width - 1 downto 0);

  -- all of b's bits anded with ith bit of a
  signal operand_b_masked : std_logic_vector(bit_width - 1 downto 0);

  -- ALU inputs and outputs
  signal alu_a      : std_logic_vector(bit_width - 1 downto 0);
  signal alu_b      : std_logic_vector(bit_width - 1 downto 0);
  signal alu_result : std_logic_vector(bit_width - 1 downto 0);

begin

  result             <= out_reg_r;
  operand_a_last_bit <= a_last_reg_r(0);

  bit_scanner : entity work.msb_bitscanner(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      signal_in  => operand_a,
      signal_out => bit_scanner_out
    );

  p_shift_regs : process (clk, operand_a, a_reg_r, a_last_reg_r, reset, shift_reg_enable, shift_reg_shift_enable) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        a_reg_r      <= (others => '0');
        a_last_reg_r <= (others => '0');
      elsif (shift_reg_enable = '1') then
        a_reg_r      <= operand_a;
        a_last_reg_r <= bit_scanner_out;
      elsif (shift_reg_shift_enable = '1') then
        a_reg_r      <= '0' & a_reg_r(bit_width - 1 downto 1);
        a_last_reg_r <= '0' & a_last_reg_r(bit_width - 1 downto 1);
      end if;
    end if;

  end process p_shift_regs;

  bitwise_masker_b_a : entity work.bitwise_masker(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      signal_in       => operand_b,
      set_mask_values => a_reg_r(0),

      signal_out => operand_b_masked
    );

  alu_b_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0 => operand_b_masked,
      a1 => modulus,
      b  => alu_b,

      sel => alu_b_select
    );

  alu_a_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0 => out_reg_left_shifted,
      a1 => out_reg_r,
      b  => alu_a,

      sel => alu_a_select
    );

  alu : entity work.alu(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      operand_a => alu_a,
      operand_b => alu_b,
      result    => alu_result,
      opcode    => alu_opcode,
      less_than => alu_less_than
    );

  p_out_reg : process (clk, reset, out_reg_enable, alu_result) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        out_reg_r <= (others => '0');
      elsif (out_reg_enable = '1') then
        out_reg_r <= alu_result;
      end if;
    end if;

  end process p_out_reg;

  p_out_reg_left_shifter : process (out_reg_r) is
  begin

    out_reg_left_shifted <= out_reg_r(bit_width - 2  downto 0) & '0';

  end process p_out_reg_left_shifter;

end architecture rtl;

