library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

entity uvvm_tb is
end entity uvvm_tb;

architecture func of uvvm_tb is

begin
  p_main: process
  begin
    log("Starting simulations.");
    
    std.env.stop;
    wait;
  end process p_main;
  
end architecture func;
