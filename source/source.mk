alu: utils
msb_bitscanner: utils

monpro: monpro_datapath monpro_control
monpro_datapath: alu mux_2to1 bitwise_masker msb_bitscanner
monpro_control: utils

modexp: modexp_datapath modexp_control
modexp_datapath: monpro mux_3to1 mux_2to1 msb_bitscanner

modmul: modmul_control modmul_datapath
modmul_datapath: mux_2to1 bitwise_masker msb_bitscanner
modmul_control: utils

rsa_core: rsa_core_control rsa_core_datapath
