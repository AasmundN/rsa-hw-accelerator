## RSA Hardware Accelerator

Hardware accelerator for RSA encryption and decryption written in VHDL.

### Project setup and usage

**Running simulations**

This project has been developed using the open source VHDL compiler [GHDL](https://github.com/ghdl/ghdl) version _4.1.0_. Other versions might work but have not been tested. The provided _Makefile_ can then be used to compile the project and run simulations. 

```
# compile all project sources
make all

# run testbench uvvm_tb
make uvvm_tb.sim

# view uvvm_tb waveform in gtkwave
make uvvm_tb.wave

# display help
make help
```
The _Makefile_ is taken from [pacalet/mkvhdl](https://github.com/pacalet/mkvhdl). 

**Code editor setup**

For code completion and intellisense use the [VHDL-LS/rust_hdl](https://github.com/VHDL-LS/rust_hdl) language server. A configuration file _vhdl_ls.toml_ is provided.

**Dependencies**

The _lib_ directory contains external project dependencies:

- [uvvm_util](https://github.com/UVVM/UVVM/tree/master/uvvm_util)
