library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rsa_core is
  generic (
    c_block_size : integer := 256
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
    -- Message that will be sent out is valid
    msgin_valid : in    std_logic;
    -- Slave ready to accept a new message
    msgin_ready : out   std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgin_data : in    std_logic_vector(c_block_size - 1 downto 0);
    -- Indicates boundary of last packet
    msgin_last : in    std_logic;

    -----------------------------------------------------------------------------
    -- Master msgout interface
    -----------------------------------------------------------------------------
    -- Message that will be sent out is valid
    msgout_valid : out   std_logic;
    -- Slave ready to accept a new message
    msgout_ready : in    std_logic;
    -- Message that will be sent out of the rsa_msgin module
    msgout_data : out   std_logic_vector(c_block_size - 1 downto 0);
    -- Indicates boundary of last packet
    msgout_last : out   std_logic;

    -----------------------------------------------------------------------------
    -- Interface to the register block
    -----------------------------------------------------------------------------
    key_e_d    : in    std_logic_vector(c_block_size - 1 downto 0);
    key_n      : in    std_logic_vector(c_block_size - 1 downto 0);
    rsa_status : out   std_logic_vector(31 downto 0)
  );
end entity rsa_core;

architecture rtl of rsa_core is

  signal modmul_valid     : std_logic;
  signal modexp_in_ready  : std_logic;
  signal modexp_out_valid : std_logic;

begin

  control : entity work.rsa_core_control(rtl)
    port map (
      clk              => clk,
      reset            => reset_n,
      msgin_valid      => msgin_valid,
      msgin_ready      => msgin_ready,
      msgin_last       => msgin_last,
      msgout_last      => msgout_last,
      msgout_ready     => msgout_ready,
      msgout_valid     => msgout_valid,
      modmul_valid     => modmul_valid,
      modexp_in_ready  => modexp_in_ready,
      modexp_out_valid => modexp_out_valid
    );

end architecture rtl;
