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
    operand_m_bar : in    std_logic_vector(bit_width - 1 downto 0);
    operand_x_bar : in    std_logic_vector(bit_width - 1 downto 0);
    operand_e     : in    std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Internal register control
    -----------------------------------------------------------------------------
    outreg_enable         : in    std_logic;
    shiftreg_enable       : in    std_logic;
    shiftreg_shift_enable : in    std_logic;
    mreg_enable           : in    std_logic;

    -----------------------------------------------------------------------------
    -- Serial output of shift registers
    -----------------------------------------------------------------------------
    current_e_bit : out   std_logic;
    is_e_bit_last : out   std_logic;

    -----------------------------------------------------------------------------
    -- MUX selection
    -----------------------------------------------------------------------------
    outreg_in_sel : in    std_logic;
    monpro_b_sel  : in    std_logic_vector(1 downto 0);

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
  signal outreg_in   : std_logic_vector(bit_width - 1 downto 0);

  -- Internal registers
  signal outreg_r   : std_logic_vector(bit_width - 1 downto 0);
  signal mreg_r     : std_logic_vector(bit_width - 1 downto 0);
  signal ereg_r     : std_logic_vector(bit_width - 1 downto 0);
  signal elastreg_r : std_logic_vector(bit_width - 1 downto 0);

  -- Bit scanner
  signal bit_scanner_out : std_logic_vector(bit_width - 1 downto 0);

begin

  result        <= outreg_r;
  current_e_bit <= ereg_r(0);
  is_e_bit_last <= elastreg_r(0);

  monpro : entity work.monpro(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk          => clk,
      modulus      => modulus,
      operand_a    => outreg_r,
      operand_b    => monpro_b_in,
      result       => monpro_out,
      enable       => monpro_enable,
      output_valid => monpro_output_valid
    );

  outreg_in_mux : entity work.mux_2to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0  => monpro_out,
      a1  => operand_x_bar,
      b   => outreg_in,
      sel => outreg_in_sel
    );

  monpro_b_mux : entity work.mux_3to1(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      a0  => outreg_r,
      a1  => (others => '1'),
      a2  => mreg_r,
      b   => monpro_b_in,
      sel => monpro_b_sel
    );

  outreg : process (clk, reset, outreg_enable, outreg_in) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        outreg_r <= (others => '0');
      elsif (outreg_enable = '1') then
        outreg_r <= outreg_in;
      end if;
    end if;

  end process outreg;

  mreg : process (clk, reset, mreg_enable, operand_m_bar) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        mreg_r <= (others => '0');
      elsif (mreg_enable = '1') then
        mreg_r <= operand_m_bar;
      end if;
    end if;

  end process mreg;

  shiftregs : process (clk, operand_e, ereg_r, elastreg_r, reset, shiftreg_enable, shiftreg_shift_enable) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        ereg_r     <= (others => '0');
        elastreg_r <= (others => '0');
      elsif (shiftreg_enable = '1') then
        ereg_r     <= operand_e;
        elastreg_r <= bit_scanner_out;
      elsif (shiftreg_shift_enable) then
        ereg_r     <= '0' & ereg_r(bit_width - 1 downto 1);
        elastreg_r <= '0' & elastreg_r(bit_width - 1 downto 1);
      end if;
    end if;

  end process shiftregs;

  bit_scanner : process (operand_e) is

    variable temp_output : std_logic_vector(bit_width - 1 downto 0) := (others => '0');

  begin

    for i in operand_e'range loop

      if (operand_e(i) = '1') then
        temp_output(i) := '1';
        exit;
      end if;

    end loop;

    bit_scanner_out <= temp_output;

  end process bit_scanner;

end architecture rtl;
