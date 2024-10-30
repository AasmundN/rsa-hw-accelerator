alu: utils
monpro: monpro_datapath monpro_control
monpro_datapath: alu mux_2to1 bitwise_masker
modexp: modexp_datapath modexp_control
modexp_datapath: monpro mux_3to1 mux_2to1 msb_bitscanner
modmul_datapath: mux_2to1 bitwise_masker msb_bitscanner
modmul: modmul_control
rsa_core: rsa_core_control rsa_core_datapath
