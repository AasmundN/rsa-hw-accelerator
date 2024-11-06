library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- Utils
  use work.utils.all;

entity rsa_core is
  generic (
    c_block_size : integer := 8;
    num_cores    : integer := 3
  );
  port (
    -----------------------------------------------------------------------------
    -- Clocks and reset
    -----------------------------------------------------------------------------
    clk     : in    std_logic;
    reset_n : in    std_logic;

    -----------------------------------------------------------------------------
    -- Slave msgin interface
    -----------------------------------------------------------------------------
    msgin_valid : in    std_logic;
    msgin_ready : out   std_logic;
    msgin_data  : in    std_logic_vector(c_block_size - 1 downto 0);
    msgin_last  : in    std_logic;

    -----------------------------------------------------------------------------
    -- Master msgout interface
    -----------------------------------------------------------------------------
    msgout_valid : out   std_logic;
    msgout_ready : in    std_logic;
    msgout_data  : out   std_logic_vector(c_block_size - 1 downto 0);
    msgout_last  : out   std_logic;

    -----------------------------------------------------------------------------
    -- Interface to the register block
    -----------------------------------------------------------------------------
    key_e_d    : in    std_logic_vector(c_block_size - 1 downto 0);
    key_n      : in    std_logic_vector(c_block_size - 1 downto 0);
    r_mod_n    : in    std_logic_vector(c_block_size - 1 downto 0);
    r2_mod_n   : in    std_logic_vector(c_block_size - 1 downto 0);
    rsa_status : out   std_logic_vector(31 downto 0)
  );
end entity rsa_core;

architecture rtl of rsa_core is

  signal in_reg_enable          : std_logic;
  signal out_reg_enable         : std_logic;
  signal in_is_last_reg_enable  : std_logic;
  signal out_is_last_reg_enable : std_logic;

  signal modexp_in_ready  : std_logic_vector(num_cores - 1 downto 0);
  signal modexp_in_valid  : std_logic_vector(num_cores - 1 downto 0);
  signal modexp_out_valid : std_logic_vector(num_cores - 1 downto 0);
  signal modexp_out_ready : std_logic_vector(num_cores - 1 downto 0);

  signal current_core_id : std_logic_vector(get_bit_width(num_cores) - 1 downto 0);

begin

  rsa_status <= (others => '0');

  datapath : entity work.rsa_core_datapath
    generic map (
      bit_width => c_block_size,
      num_cores => num_cores
    )
    port map (
      clk                    => clk,
      reset                  => reset_n,
      key_n                  => key_n,
      key_e_d                => key_e_d,
      r_mod_n                => r_mod_n,
      r2_mod_n               => r2_mod_n,
      msgin_data             => msgin_data,
      msgout_data            => msgout_data,
      msgin_last             => msgin_last,
      msgout_last            => msgout_last,
      in_reg_enable          => in_reg_enable,
      out_reg_enable         => out_reg_enable,
      in_is_last_reg_enable  => in_is_last_reg_enable,
      out_is_last_reg_enable => out_is_last_reg_enable,
      modexp_in_ready        => modexp_in_ready,
      modexp_in_valid        => modexp_in_valid,
      modexp_out_ready       => modexp_out_ready,
      modexp_out_valid       => modexp_out_valid,
      current_core_id        => current_core_id
    );

  input_control : entity work.rsa_core_input_control
    generic map (
      num_cores => num_cores
    )
    port map (
      clk                   => clk,
      reset                 => reset_n,
      in_reg_enable         => in_reg_enable,
      in_is_last_reg_enable => in_is_last_reg_enable,
      msgin_valid           => msgin_valid,
      msgin_ready           => msgin_ready,
      modexp_in_ready       => modexp_in_ready,
      modexp_in_valid       => modexp_in_valid
    );

  output_control : entity work.rsa_core_output_control
    generic map (
      num_cores => num_cores
    )
    port map (
      clk                    => clk,
      reset                  => reset_n,
      out_reg_enable         => out_reg_enable,
      out_is_last_reg_enable => out_is_last_reg_enable,
      msgout_valid           => msgout_valid,
      msgout_ready           => msgout_ready,
      modexp_out_ready       => modexp_out_ready,
      modexp_out_valid       => modexp_out_valid,
      current_core_id        => current_core_id
    );

end architecture rtl;
