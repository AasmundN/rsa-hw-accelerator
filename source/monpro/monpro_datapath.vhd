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
    alu_b_select  : in    std_logic;
    alu_less_than : out   std_logic;

    -----------------------------------------------------------------------------
    -- Internal register control signals
    -----------------------------------------------------------------------------
    n_b_reg_enable         : in    std_logic;
    out_reg_enable         : in    std_logic;
    shift_reg_enable       : in    std_logic;
    shift_reg_shift_enable : in    std_logic;

    -----------------------------------------------------------------------------
    -- Main inputs and outputs
    -----------------------------------------------------------------------------
    modulus        : in    std_logic_vector(bit_width - 1 downto 0);
    modulus_length : in    std_logic_vector(bit_width - 1 downto 0);
    operand_a      : in    std_logic_vector(bit_width - 1 downto 0);
    operand_b      : in    std_logic_vector(bit_width - 1 downto 0);
    result         : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- u(0) xor (a(i) and b(0))
    -----------------------------------------------------------------------------
    is_odd : out   std_logic;

    n_bit_is_last : out   std_logic
  );
end entity monpro_datapath;

architecture rtl of monpro_datapath is

  -- b anded with ith bit of a
  signal and_b_a : std_logic_vector(bit_width - 1 downto 0);

  -- Internal registers

  signal modulus_reg_r, b_reg_r : std_logic_vector(bit_width - 1 downto 0);

  -- The intermediary result of the calculation loop
  -- requires a size of bit_width + 2 (see monpro algorithm)
  signal out_reg_r     : std_logic_vector(bit_width + 1 downto 0);
  signal a_shift_reg_r : std_logic_vector(bit_width - 1 downto 0);

  signal n_shift_reg_r : std_logic_vector(bit_width - 1 downto 0);

  -- Output from bit shifter
  signal out_reg_right_shifted : std_logic_vector(bit_width + 1 downto 0);

  -- ALU inputs and outputs
  signal alu_b      : std_logic_vector(bit_width + 1 downto 0);
  signal alu_result : std_logic_vector(bit_width + 1 downto 0);

  signal alu_b_mux_a0_intermediary : std_logic_vector(bit_width + 1 downto 0);
  signal alu_b_mux_a1_intermediary : std_logic_vector(bit_width + 1 downto 0);

  signal alu_c_intermediary : std_logic_vector(bit_width + 1 downto 0);

begin

  alu_b_mux_a0_intermediary <= "00" & modulus_reg_r;
  alu_b_mux_a1_intermediary <= (others => '0');

  alu_c_intermediary <= "00" & and_b_a;

  result        <= out_reg_r(bit_width - 1 downto 0);
  is_odd        <= out_reg_right_shifted(0) xor (b_reg_r(0) and a_shift_reg_r(0));
  n_bit_is_last <= n_shift_reg_r(0);

  alu : entity work.alu(rtl)
    generic map (
      bit_width => bit_width + 2
    )
    port map (
      operand_a => out_reg_right_shifted,
      operand_b => alu_b,
      operand_c => alu_c_intermediary,
      result    => alu_result,
      opcode    => alu_opcode,
      less_than => alu_less_than
    );

  bitwise_masker_b_a : entity work.bitwise_masker(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      signal_in       => b_reg_r,
      set_mask_values => a_shift_reg_r(0),

      signal_out => and_b_a
    );

  alu_b_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width + 2
    )
    port map (
      a0  => alu_b_mux_a0_intermediary,
      a1  => alu_b_mux_a1_intermediary,
      b   => alu_b,
      sel => alu_b_select
    );

  -- Right shift one bit
  bit_shifter : process (out_reg_r) is
  begin

    out_reg_right_shifted <= '0' & out_reg_r(bit_width + 1 downto 1);

  end process bit_shifter;

  out_reg : process (clk, reset, out_reg_enable, alu_result) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        out_reg_r <= (others => '0');
      elsif (out_reg_enable = '1') then
        out_reg_r <= alu_result;
      end if;
    end if;

  end process out_reg;

  -- Latch modulus and operand_b inputs
  n_b_reg : process (clk, n_b_reg_enable) is
  begin

    if rising_edge(clk) then
      if (n_b_reg_enable = '1') then
        modulus_reg_r <= modulus;
        b_reg_r       <= operand_b;
      end if;
    end if;

  end process n_b_reg;

  shift_reg : process (clk, reset, shift_reg_enable, shift_reg_shift_enable, alu_result) is
  begin

    if rising_edge(clk) then
      if (shift_reg_enable = '1') then
        a_shift_reg_r <= operand_a;
        n_shift_reg_r <= modulus_length;
      -- Shift register content
      elsif (shift_reg_shift_enable = '1') then
        -- Nono?
        a_shift_reg_r <= '0' & a_shift_reg_r(bit_width - 1 downto 1);
        n_shift_reg_r <= '0' & n_shift_reg_r(bit_width - 1 downto 1);
      end if;
    end if;

  end process shift_reg;

end architecture rtl;
