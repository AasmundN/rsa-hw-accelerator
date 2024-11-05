library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity rsa_core_datapath is
  generic (
    bit_width : integer := 4;
    num_cores : integer := 2
  );
  port (
    clk   : in    std_logic;
    reset : in    std_logic;

    key_n    : in    std_logic_vector(bit_width - 1 downto 0);
    key_e_d  : in    std_logic_vector(bit_width - 1 downto 0);
    r_mod_n  : in    std_logic_vector(bit_width - 1 downto 0);
    r2_mod_n : in    std_logic_vector(bit_width - 1 downto 0);

    -- Input/output
    msgin_data  : in    std_logic_vector(bit_width - 1 downto 0);
    msgout_data : out   std_logic_vector(bit_width - 1 downto 0);
    msgin_last  : in    std_logic;
    msgout_last : out   std_logic;

    -- Internal register control
    in_reg_enable          : in    std_logic;
    out_reg_enable         : in    std_logic;
    in_is_last_reg_enable  : in    std_logic;
    out_is_last_reg_enable : in    std_logic;

    -- Modexp control
    modexp_in_ready  : out   std_logic_vector(num_cores - 1 downto 0);
    modexp_in_valid  : in    std_logic_vector(num_cores - 1 downto 0);
    modexp_out_ready : in    std_logic_vector(num_cores - 1 downto 0);
    modexp_out_valid : out   std_logic_vector(num_cores - 1 downto 0)
  );
end entity rsa_core_datapath;

architecture rtl of rsa_core_datapath is

  -- Internal registers
  signal in_reg_r          : std_logic_vector(bit_width - 1 downto 0);
  signal out_reg_r         : std_logic_vector(bit_width - 1 downto 0);
  signal in_is_last_reg_r  : std_logic;
  signal out_is_last_reg_r : std_logic;

  signal modexp_out : std_logic_vector(bit_width - 1 downto 0);

  component modexp is
    generic (
      bit_width : integer
    );
    port (
      clk           : in    std_logic;
      reset         : in    std_logic;
      modulus       : in    std_logic_vector(bit_width - 1 downto 0);
      operand_m_bar : in    std_logic_vector(bit_width - 1 downto 0);
      operand_x_bar : in    std_logic_vector(bit_width - 1 downto 0);
      operand_e     : in    std_logic_vector(bit_width - 1 downto 0);
      result        : out   std_logic_vector(bit_width - 1 downto 0);
      in_valid      : in    std_logic;
      in_ready      : out   std_logic;
      out_ready     : in    std_logic;
      out_valid     : out   std_logic
    );
  end component modexp;

begin

  msgout_data <= out_reg_r;
  msgout_last <= out_is_last_reg_r;

  -- Instanciate all encryption cores

  modexp_cores : for i in 0 to num_cores - 1 generate

    modexp_i : component modexp
      generic map (
        bit_width => bit_width
      )
      port map (
        clk           => clk,
        reset         => reset,
        modulus       => key_n,
        operand_m_bar => in_reg_r,
        operand_x_bar => r_mod_n,
        operand_e     => key_e_d,
        result        => modexp_out,
        in_valid      => modexp_in_valid(i),
        in_ready      => modexp_in_ready(i),
        out_ready     => modexp_out_ready(i),
        out_valid     => modexp_out_valid(i)
      );

  end generate modexp_cores;

  p_in_reg : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        in_reg_r <= (others => '0');
      elsif (in_reg_enable = '1') then
        in_reg_r <= msgin_data;
      end if;
    end if;

  end process p_in_reg;

  p_out_reg : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        out_reg_r <= (others => '0');
      elsif (out_reg_enable = '1') then
        out_reg_r <= modexp_out;
      end if;
    end if;

  end process p_out_reg;

  p_in_is_last_reg : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        in_is_last_reg_r <= '0';
      elsif (in_is_last_reg_enable = '1') then
        in_is_last_reg_r <= msgin_last;
      end if;
    end if;

  end process p_in_is_last_reg;

  p_out_is_last_reg : process (clk) is
  begin

    if rising_edge(clk) then
      if (reset = '1') then
        out_is_last_reg_r <= '0';
      elsif (out_is_last_reg_enable = '1') then
        -- OBSOBS! This needs to come from modexp
        out_is_last_reg_r <= '1';
      end if;
    end if;

  end process p_out_is_last_reg;

end architecture rtl;

configuration conf of rsa_core_datapath is
  for rtl
    for all : modexp
      use entity work.modexp(rtl);
    end for;
  end for;
end configuration conf;
