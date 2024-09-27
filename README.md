## RSA Hardware Accelerator

Hardware accelerator for RSA encryption and decryption written in VHDL. The _docs_ directory contains additional documentation, including high level code for the algorithm as implemented in hardware.


### Prerequisites

This project uses the open source VHDL compiler [GHDL](https://github.com/ghdl/ghdl) for running simulations. Use [gtkwave](https://github.com/gtkwave/gtkwave) to view waveform files. [YOSYS](https://github.com/YosysHQ/yosys) in combination with [yosys-plugin-ghdl](https://github.com/ghdl/ghdl-yosys-plugin) is used for generating schematics. The output _.dot_ files are transformed to _.svg_ using [graphviz](https://gitlab.com/graphviz/graphviz).

Installation is easy as [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build) comes with prebuilt binaries for all of the mentioned tools, with the exception of _graphviz_ which must be installed separately. 

> NOTE: _arm64_ users must install the _x64_ version and run with _Rosetta_.

Make sure to update your shell environment to include the binary files in the path. _GHDL_PREFIX_ must also be added.

```
# example .zshrc
export GHDL_PREFIX="/usr/local/oss-cad-suite/lib/ghdl"
export PATH="/usr/local/oss-cad-suite/bin:$PATH"
```

To ensure consistent code styling the project uses [vhdl-style-guide](https://github.com/jeremiah-c-leary/vhdl-style-guide). This must also be installed separately. Styling config is provided in _vsg_config.json_.

### Running simulations

This project has been developed using GHDL version _5.0.0-dev_. Other versions might work but have not been tested. The provided _Makefile_ can then be used to compile the project, run simulations and view schematics. Note that synthesis using GHDL is an experimental feature and should only be used for simple testing.

> NOTE: all testbenches must be name UNIT_tb, where UNIT is the DUT.

```
# compile all project sources
make all

# run testbench uvvm_tb
make uvvm_tb.sim

# view uvvm_tb waveform in gtkwave
make uvvm_tb.wave

# generate and view schematics
make UNIT.schema

# format all source and test files
make format

# display help
make help
```

The Makefile is a modified version of [pacalet/mkvhdl](https://github.com/pacalet/mkvhdl). See the github for detailed information on how to use it. The _config_ file contains configuration for make.

### Code editor setup

For code completion and intellisense use the [VHDL-LS/rust_hdl](https://github.com/VHDL-LS/rust_hdl) language server. A configuration file _vhdl_ls.toml_ is provided. See _vhdl-style-guide_ documention for instructions on setting up format on save.

### Dependencies

The _lib_ directory contains external project dependencies:

- [uvvm_util](https://github.com/UVVM/UVVM/tree/master/uvvm_util)
