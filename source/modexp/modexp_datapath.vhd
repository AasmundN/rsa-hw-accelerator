library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modexp_datapath is
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
    -- Modulus (n) of the modulo operation
    -----------------------------------------------------------------------------
    modulus : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Operands of modular exponentiation
    -----------------------------------------------------------------------------
    operand_m         : in    std_logic_vector(bit_width - 1 downto 0);
    operand_x_bar     : in    std_logic_vector(bit_width - 1 downto 0);
    operand_e         : in    std_logic_vector(bit_width - 1 downto 0);
    operand_r_sq_modn : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Internal register control
    -----------------------------------------------------------------------------
    out_reg_enable         : in    std_logic;
    shift_reg_enable       : in    std_logic;
    shift_reg_shift_enable : in    std_logic;
    m_reg_enable           : in    std_logic;

    -----------------------------------------------------------------------------
    -- Serial output of shift registers
    -----------------------------------------------------------------------------
    e_current_bit : out   std_logic;
    e_bit_is_last : out   std_logic;

    -----------------------------------------------------------------------------
    -- MUX selection
    -----------------------------------------------------------------------------
    out_reg_in_select : in    std_logic_vector(1 downto 0);
    monpro_b_select   : in    std_logic_vector(1 downto 0);
    m_reg_in_select   : in    std_logic;

    -----------------------------------------------------------------------------
    -- Monpro control signals
    -----------------------------------------------------------------------------
    monpro_enable       : in    std_logic;
    monpro_output_valid : out   std_logic
  );
end entity modexp_datapath;

architecture rtl of modexp_datapath is

  -- Monpro intermediary signals
  signal monpro_out  : std_logic_vector(bit_width - 1 downto 0);
  signal monpro_b_in : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_in  : std_logic_vector(bit_width - 1 downto 0);
  signal m_reg_in    : std_logic_vector(bit_width - 1 downto 0);

  -- Internal registers
  signal out_reg_r    : std_logic_vector(bit_width - 1 downto 0);
  signal m_reg_r      : std_logic_vector(bit_width - 1 downto 0);
  signal e_reg_r      : std_logic_vector(bit_width - 1 downto 0);
  signal e_last_reg_r : std_logic_vector(bit_width - 1 downto 0);

begin

  result        <= out_reg_r;
  e_current_bit <= e_reg_r(e_reg_r'left);
  e_bit_is_last <= e_last_reg_r(e_last_reg_r'left);

  monpro : entity work.monpro(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk          => clk,
      modulus      => modulus,
      operand_a    => out_reg_r,
      operand_b    => monpro_b_in,
      result       => monpro_out,
      enable       => monpro_enable,
      output_valid => monpro_output_valid
    );

  out_reg_in_mux : entity work.mux_3to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0  => monpro_out,
      a1  => operand_x_bar,
      a2  => operand_r_sq_modn,
      b   => out_reg_in,
      sel => out_reg_in_select
    );

  monpro_b_mux : entity work.mux_3to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0  => out_reg_r,
      a1  => std_logic_vector(to_unsigned(1, bit_width)),
      a2  => m_reg_r,
      b   => monpro_b_in,
      sel => monpro_b_select
    );

  m_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0  => out_reg_r,
      a1  => operand_m,
      b   => m_reg_in,
      sel => m_reg_in_select
    );

  out_reg : process (clk, reset, out_reg_enable, out_reg_in) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        out_reg_r <= (others => '0');
      elsif (out_reg_enable = '1') then
        out_reg_r <= out_reg_in;
      end if;
    end if;

  end process out_reg;

  m_reg : process (clk, m_reg_enable, operand_m) is
  begin

    if rising_edge(clk) then
      if (m_reg_enable = '1') then
        m_reg_r <= m_reg_in;
      end if;
    end if;

  end process m_reg;

  shift_regs : process (clk, operand_e, e_reg_r, e_last_reg_r, shift_reg_enable, shift_reg_shift_enable) is
  begin

    if rising_edge(clk) then
      if (shift_reg_enable = '1') then
        e_reg_r      <= operand_e;
        e_last_reg_r <= std_logic_vector(to_unsigned(1, bit_width));
      elsif (shift_reg_shift_enable = '1') then
        e_reg_r      <= e_reg_r(bit_width - 2 downto 0) & '0';
        e_last_reg_r <= e_last_reg_r(bit_width - 2 downto 0) & '0';
      end if;
    end if;

  end process shift_regs;

end architecture rtl;
