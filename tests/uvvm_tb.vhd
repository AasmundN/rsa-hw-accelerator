library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

entity uvvm_tb is
end entity uvvm_tb;

architecture func of uvvm_tb is
  constant log_file_name : string := "_uvvm_tb.log";
begin
  p_main: process
  begin
    set_log_file_name(log_file_name);
    

    log("Starting simulation");

    wait for 10 ns;

    log("End of simulation");

    report_alert_counters(void);
    
    std.env.stop;
    wait;
  end process p_main;
  
end architecture func;
