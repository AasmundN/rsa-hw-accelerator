library ieee;
  use ieee.std_logic_1164.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;

entity uvvm_tb is
end entity uvvm_tb;

architecture func of uvvm_tb is

begin

  p_main : process is
  begin

    log(ID_CTRL, "Starting simulation");

    wait for 10 ns;

    log("End of simulation");

    report_alert_counters(void);

    std.env.stop;
    wait;

  end process p_main;

end architecture func;
