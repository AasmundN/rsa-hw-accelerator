library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

  -- Utils
  use work.utils.all;

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

    current_core_id : in    std_logic_vector(get_bit_width(num_cores) - 1 downto 0);

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

  type modexp_out_t is array (num_cores - 1 downto 0) of std_logic_vector(bit_width - 1 downto 0);

  signal modexp_out : modexp_out_t;

  signal modexp_out_msg_last : std_logic_vector(num_cores - 1 downto 0);

  signal key_n_length : std_logic_vector(bit_width - 1 downto 0);

  component modexp is
    generic (
      bit_width : integer
    );
    port (
      clk            : in    std_logic;
      reset          : in    std_logic;
      modulus        : in    std_logic_vector(bit_width - 1 downto 0);
      modulus_length : in    std_logic_vector(bit_width - 1 downto 0);
      base           : in    std_logic_vector(bit_width - 1 downto 0);
      exponent       : in    std_logic_vector(bit_width - 1 downto 0);
      r_mod_n        : in    std_logic_vector(bit_width - 1 downto 0);
      r2_mod_n       : in    std_logic_vector(bit_width - 1 downto 0);
      result         : out   std_logic_vector(bit_width - 1 downto 0);
      in_is_last     : in    std_logic;
      out_is_last    : out   std_logic;
      in_valid       : in    std_logic;
      in_ready       : out   std_logic;
      out_ready      : in    std_logic;
      out_valid      : out   std_logic
    );
  end component modexp;

begin

  msgout_data <= out_reg_r;
  msgout_last <= out_is_last_reg_r;

  -- Instanciate all encryption cores

  modexp_cores : for i in 0 to num_cores - 1 generate

    modexp_core : component modexp
      generic map (
        bit_width => bit_width
      )
      port map (
        clk            => clk,
        reset          => reset,
        modulus        => key_n,
        modulus_length => key_n_length,
        base           => in_reg_r,
        r_mod_n        => r_mod_n,
        r2_mod_n       => r2_mod_n,
        exponent       => key_e_d,
        result         => modexp_out(i),
        out_is_last    => modexp_out_msg_last(i),
        in_is_last     => in_is_last_reg_r,
        in_valid       => modexp_in_valid(i),
        in_ready       => modexp_in_ready(i),
        out_ready      => modexp_out_ready(i),
        out_valid      => modexp_out_valid(i)
      );

  end generate modexp_cores;

  msb_bitscanner : entity work.msb_bitscanner
    generic map (
      bit_width => bit_width
    )
    port map (
      signal_in  => key_n,
      signal_out => key_n_length
    );

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
        -- Makes sure only
        out_reg_r <= modexp_out(to_integer(unsigned(current_core_id)));
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
        out_is_last_reg_r <= modexp_out_msg_last(to_integer(unsigned(current_core_id)));
      end if;
    end if;

  end process p_out_is_last_reg;

end architecture rtl;

configuration conf of rsa_core_datapath is
  for rtl
    for modexp_cores
      for all : modexp
        use entity work.modexp(rtl);
      end for;
    end for;
  end for;
end configuration conf;
