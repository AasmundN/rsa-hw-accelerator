library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rsa_core_datapath is
  generic (
    bit_width : integer := 256
  );
  port (
    clk   : in    std_logic;
    reset : in    std_logic;

    key_n   : in    std_logic_vector(bit_width - 1 downto 0);
    key_e_d : in    std_logic_vector(bit_width - 1 downto 0);

    -- Precomupted operand received from AXI Slave. x_bar = x in montgomery space
    x_bar             : in    std_logic_vector(bit_width - 1 downto 0);
    montgomery_factor : in    std_logic_vector(bit_width - 1 downto 0); -- Place holder name (r-value)

    msgin_data    : in    std_logic_vector(bit_width - 1 downto 0);
    msgout_data   : in    std_logic_vector(bit_width - 1 downto 0);
    modmul_enable : out   std_logic;
    modmul_valid  : out   std_logic;

    modexp_in_ready : in    std_logic;
    modexp_in_valid : out   std_logic;

    modexp_out_ready : out   std_logic;
    modexp_out_valid : in    std_logic
  );
end entity rsa_core_datapath;

architecture rtl of rsa_core_datapath is

  -- Internal registers
  signal in_reg_r  : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_r : std_logic_vector(bit_width - 1 downto 0);
  signal m_reg_r   : std_logic_vector(bit_width - 1 downto 0);

  -- Intermediary signals
  signal modmul_out, modexp_out : std_logic_vector(bit_width - 1 downto 0);

begin

  modmul : entity work.modmul(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk          => clk,
      modulus      => key_n,
      operand_a    => in_reg_r,
      operand_b    => montgomery_factor,
      result       => modmul_out,
      enable       => modmul_enable,
      output_valid => modmul_valid
    );

  modexp : entity work.modexp(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk           => clk,
      reset         => reset,
      modulus       => key_n,
      operand_m_bar => m_reg_r,
      operand_x_bar => x_bar,
      operand_e     => key_e_d,
      result        => modexp_out,
      in_valid      => modexp_in_valid,
      in_ready      => modexp_in_ready,
      out_ready     => modexp_out_ready,
      out_valid     => modexp_out_valid
    );

end architecture rtl;
