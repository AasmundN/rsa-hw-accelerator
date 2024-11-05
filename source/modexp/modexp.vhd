library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity modexp is
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
    operand_m : in    std_logic_vector(bit_width - 1 downto 0);
    operand_x_bar : in    std_logic_vector(bit_width - 1 downto 0);
    operand_e     : in    std_logic_vector(bit_width - 1 downto 0);
    operand_r_sq_modn : in std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Result of calculation
    -----------------------------------------------------------------------------
    result : out   std_logic_vector(bit_width - 1 downto 0);

    -----------------------------------------------------------------------------
    -- Ready/valid handshake signals
    -----------------------------------------------------------------------------
    in_valid  : in    std_logic;
    in_ready  : out   std_logic;
    out_ready : in    std_logic;
    out_valid : out   std_logic
  );
end entity modexp;

architecture rtl of modexp is

  -- Internal register control
  signal out_reg_enable         : std_logic;
  signal shift_reg_enable       : std_logic;
  signal shift_reg_shift_enable : std_logic;
  signal m_reg_enable           : std_logic;

  -- e loop signals
  signal e_current_bit : std_logic;
  signal e_bit_is_last : std_logic;

  -- MUX control
  signal out_reg_in_select : std_logic_vector(1 downto 0);
  signal monpro_b_select   : std_logic_vector(1 downto 0);
  signal m_reg_in_select   : std_logic;
  

  -- Monpro control
  signal monpro_enable       : std_logic;
  signal monpro_output_valid : std_logic;

begin

  datapath : entity work.modexp_datapath(rtl)
    generic map (
      bit_width => bit_width
    )
    port map (
      clk                    => clk,
      reset                  => reset,
      modulus                => modulus,
      operand_m          => operand_m,
      operand_x_bar          => operand_x_bar,
      operand_e              => operand_e,
      operand_r_sq_modn => operand_r_sq_modn,
      result                 => result,
      out_reg_enable         => out_reg_enable,
      shift_reg_enable       => shift_reg_enable,
      shift_reg_shift_enable => shift_reg_shift_enable,
      m_reg_enable           => m_reg_enable,
      e_current_bit          => e_current_bit,
      e_bit_is_last          => e_bit_is_last,
      out_reg_in_select      => out_reg_in_select,
      monpro_b_select        => monpro_b_select,
      m_reg_in_select        => m_reg_in_select,
      monpro_enable          => monpro_enable,
      monpro_output_valid    => monpro_output_valid
    );

  control : entity work.modexp_control(rtl)
    port map (
      clk                    => clk,
      reset                  => reset,
      in_valid               => in_valid,
      in_ready               => in_ready,
      out_ready              => out_ready,
      out_valid              => out_valid,
      out_reg_enable         => out_reg_enable,
      shift_reg_enable       => shift_reg_enable,
      shift_reg_shift_enable => shift_reg_shift_enable,
      m_reg_enable           => m_reg_enable,
      e_current_bit          => e_current_bit,
      e_bit_is_last          => e_bit_is_last,
      out_reg_in_select      => out_reg_in_select,
      monpro_b_select        => monpro_b_select,
      m_reg_in_select        => m_reg_in_select,
      monpro_enable          => monpro_enable,
      monpro_output_valid    => monpro_output_valid
    );

end architecture rtl;
