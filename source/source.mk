alu: utils
monpro: monpro_datapath monpro_control
monpro_datapath: alu mux_2to1
modexp: modexp_datapath
<<<<<<< HEAD
modexp_datapath: monpro mux_3to1 mux_2to1 msb_bitscanner
rsa_core: rsa_core_control
=======
modexp_datapath: monpro mux_3to1 mux_2to1
rsa_core: rsa_core_control rsa_core_datapath
>>>>>>> origin/main
