## RSA Hardware Accelerator

Hardware accelerator for RSA encryption and decryption written in VHDL.


### Prerequisites

This project uses the open source VHDL compiler [GHDL](https://github.com/ghdl/ghdl) for running simulations. Use [gtkwace](https://github.com/gtkwave/gtkwave) to view waveform files. [YOSYS](https://github.com/YosysHQ/yosys) in combination with [yosys-plugin-ghdl](https://github.com/ghdl/ghdl-yosys-plugin) is used for generating schematics. The output _.dot_ files are transformed to _.svg_ using [graphviz](https://gitlab.com/graphviz/graphviz).

Installation is easy as [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) comes with prebuilt binaries for all of the mentioned tools, with the exception of _graphviz_ which must be installed separately. 

> Note: Arm64 Mac users must install the _x64_ version and run with _Rosetta_.

Make sure to update your shell environment to include the binary files in the path. _GHDL_PREFIX_ must also be added.

```
# example .zshrc
export GHDL_PREFIX="/usr/local/oss-cad-suite/lib/ghdl"
export PATH="/usr/local/oss-cad-suite/bin:$PATH"

```

### Running simulations

This project has been developed using GHDL version _5.0.0-dev_. Other versions might work but have not been tested. The provided _Makefile_ can then be used to compile the project, run simulations and view schematics. Note that synthesis using GHDL is an experimental feature and should only be used for simple testing.

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

The _Makefile_ is a modified version of [pacalet/mkvhdl](https://github.com/pacalet/mkvhdl). See the github for detailed information on how to use it.

### Code editor setup

For code completion and intellisense use the [VHDL-LS/rust_hdl](https://github.com/VHDL-LS/rust_hdl) language server. A configuration file _vhdl_ls.toml_ is provided.

### Dependencies

The _lib_ directory contains external project dependencies:

- [uvvm_util](https://github.com/UVVM/UVVM/tree/master/uvvm_util)
