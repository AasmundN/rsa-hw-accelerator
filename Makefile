# Copyright © Telecom Paris
# Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
#
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

# default goal
.DEFAULT_GOAL := help

# phony targets
.PHONY: help long-help clean

# Compilation is not parallel-safe because most tools use per-library shared
# files that they update after each compilation.
.NOTPARALLEL:

# multiple goals not tested
ifneq ($(words $(MAKECMDGOALS)),1)
ifneq ($(words $(MAKECMDGOALS)),0)
$(error "multiple goals not supported yet")
endif
endif

# absolute real path of TOP directory
TOP := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# project name
PROJECT := $(notdir $(TOP))
# name of configuration file
CONFIG := config

# include configuration file
ifneq ($(wildcard $(TOP)/$(CONFIG)),)
include $(TOP)/$(CONFIG)
endif

# compute configuration variables
# simulator (ghdl, vsim or xsim)
SIM ?= ghdl
# GUI mode
GUI ?= no
ifneq ($(GUI),yes)
ifneq ($(GUI),no)
$(error "$(GUI): invalid GUI value")
endif
endif
GHDLAFLAGS ?= --std=08 -frelaxed -Wno-hide -Wno-shared
GHDLRFLAGS ?= --std=08 -frelaxed -Wno-hide -Wno-shared
GHDLRUNOPTS ?=
VCOMFLAGS ?= -2008
VSIMFLAGS ?=
XVHDLFLAGS ?= -2008
XELABFLAGS ?=
XSIMFLAGS ?=
ifeq ($(SIM),ghdl)
COM = ghdl -a $(GHDLAFLAGS) --work=$(LIBNAME) $<
ELAB := true
ifeq ($(GUI),yes)
RUN = ghdl -r $(GHDLRFLAGS) --work=$(LIBNAME) $(UNIT) $(GHDLRUNOPTS) --wave=$(UNIT).ghw; \
      printf 'GHW file: %s.ghw\nUse, e.g., GTKWave to display the GHW file\n' '$(DIR)/$(UNIT)'
else
RUN = ghdl -r $(GHDLRFLAGS) --work=$(LIBNAME) $(UNIT) $(GHDLRUNOPTS)
endif
else ifeq ($(SIM),vsim)
COM = vcom $(VCOMFLAGS) -work $(LIBNAME) $<
ELAB := true
ifeq ($(GUI),yes)
RUN = vsim $(VSIMFLAGS) $(LIBNAME).$(UNIT)
else
RUN = vsim -c $(VSIMFLAGS) $(LIBNAME).$(UNIT)
endif
else ifeq ($(SIM),xsim)
COM = xvhdl $(XVHDLFLAGS) --work $(LIBNAME) $< $(if $(VERBOSE),,> /dev/null)
ELAB = xelab $(XELABFLAGS) $(LIBNAME).$(UNIT)
ifeq ($(GUI),yes)
RUN = xsim -gui $(XSIMFLAGS) $(LIBNAME).$(UNIT)
else
RUN = xsim $(XSIMFLAGS) $(LIBNAME).$(UNIT)
endif
else
$(error "$(SIM): invalid SIM value")
endif
# temporary build directory
DIR ?= /tmp/$(USER)/$(PROJECT)/$(SIM)
# tags sub-directory of DIR
TAGS := .tags
# compilation mode:
# - "work":    the default target library is work,
# - "dirname": the default target library is the one with same name as the
#   directory of the source file
MODE ?= work
ifneq ($(MODE),work)
ifneq ($(MODE),dirname)
$(error invalid MODE value: $(MODE))
endif
endif
# verbosity level: 0: quiet, 1: verbose
V ?= 0
ifeq ($(V),0)
.SILENT:
VERBOSE :=
else ifeq ($(V),1)
VERBOSE := yes
else
$(error invalid V value: $(V))
endif

# help messages and goals
define HELP_message
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable         valid values    description (current value)
    DIR          -               temporary build directory ($(DIR))
    GHDLAFLAGS   -               GHDL analysis options ($(GHDLAFLAGS))
    GHDLRFLAGS   -               GHDL simulation options ($(GHDLRFLAGS))
    GHDLRUNOPTS  -               GHDL RUNOPTS options ($(GHDLRUNOPTS))
    GUI          yes|no          use Graphical User Interface ($(GUI))
    MODE         work|dirname    default target library ($(MODE))
    SIM          ghdl|vsim|xsim  simulation toolchain ($(SIM))
    SKIP         -               UNITs to ignore for compilation ($(SKIP))
    V            0|1             verbosity level ($(V))
    VCOMFLAGS    -               Modelsim analysis options ($(VCOMFLAGS))
    VSIMFLAGS    -               Modelsim simulation options ($(VSIMFLAGS))
    XVHDLFLAGS   -               Vivado analysis options ($(XVHDLFLAGS))
    XELABFLAGS   -               Vivado elaboration options ($(XELABFLAGS))
    XSIMFLAGS    -               Vivado simulation options ($(XSIMFLAGS))

Goals:
    help                    this help (default goal)
    long-help               print long help
    libs                    print library names
    UNIT                    compile UNIT.vhd
    units                   print existing UNITs not in SKIP
    all                     compile all source files not in SKIP
    UNIT.sim                simulate UNIT
	UNIT.wave				view UNIT waveform in gtkwave
    clean                   delete temporary build directory
endef
export HELP_message

help::
	@printf '%s\n' "$$HELP_message"

define LONG_HELP_message
This Makefile is for GNU make only and relies on conventions; if your make is
not GNU make or your project is not compatible with the conventions, please do
not use this Makefile.

The `vhdl` sub-directory contains some VHDL source files for testing.

1. The directory containing this Makefile is the `TOP` directory. All make
   commands must be launched from `TOP`:

        cd TOP; make ...

   or:

        make -C TOP ...

2. Source files are considered as indivisible units. They must be stored in the
   `TOP` directory or its sub-directories and named `UNIT.vhd` where `UNIT` is
   any combination of alphanumeric characters, plus underscores (no spaces or tabs,
   for instance). The "name" of a unit is the basename of its source file
   without the `.vhd` extension. Example: the name of unit
   `TOP/tests/cooley.vhd` is `cooley`.

3. Each unit has a default target library: `work` if `MODE=work`, or the name
   of the directory of the unit if `MODE=dirname`. Target libraries are
   automatically created if they don't exist.

4. Unit names must be unique. It is not possible to have units
   `TOP/common/version.vhd` and `TOP/tests/version.vhd`, even if `MODE=dirname`
   and their target libraries are different.

5. If there is a file named `config` in `TOP`, it is included before anything else.
   It can be used to set configuration variables to other values than the default.
   Example of `TOP/config` file:

        DIR  := /tmp/build/vsim
        GUI  := yes
        MODE := work
        SIM  := vsim
        SKIP := bogus in_progress
        V    := 1

   Variable assignments on the command line overwrite assignments in
   `TOP/config`. Example to temporarily disable the GUI for a specific
   simulation:

        make cooley_sim.sim GUI=no

6. Simulations can be launched with `make UNIT.sim` to simulate entity `UNIT`
   defined in file `UNIT.vhd`. Example: if unit `TOP/tests/cooley_sim.vhd`
   defines entity `cooley_sim` a simulation can be launched with:

        make cooley_sim.sim [VAR=VALUE...]

   Note: the simulations are launched from the `DIR` temporary build directory.
   It can matter if, for instance, a simulation reads or writes data files.

   Note: GHDL has no GUI; instead, with GHDL and `GUI=yes`, a `DIR/UNIT.ghw`
   waveform file is generated for post-simulation visualization with, e.g.,
   GTKWave.

7. Inter-unit dependencies must be declared in text files with the `.mk`
   extension stored in `TOP` or its sub-directories. The dependency syntax is:

        UNIT [UNIT...]: UNIT [UNIT...]

   where the left-hand side units depend on the right-hand side units. Example:
   if `cooley_sim.vhd` depends on `rnd_pkg.vhd` and `cooley.vhd` (that is, if
   `rnd_pkg.vhd` and `cooley.vhd` must be compiled before `cooley_sim.vhd`), the
   following can be added to a `.mk` file somewhere under `TOP`:

        cooley_sim: rnd_pkg cooley

   The sub-directory in which a `.mk` file is stored does not matter but the
   letter case matters in dependency rules: if a unit is `cooley.vhd`, its name
   is `cooley` and the dependency rules must use `cooley`, not `Cooley` or
   `COOLEY`.

   `.mk` files can also specify per-unit target libraries other than the
   defaults using `UNIT-lib` variables. Example: if `MODE=dirname` and
   `TOP/common/rnd_pkg.vhd` must be compiled in library `tests` instead of the
   default `common`, the following can be added to a `.mk` file somewhere under
   `TOP`:

        rnd_pkg-lib := tests

Other GNU make statements can be added to `.mk` files. Example if the GHDL
simulation of `cooley_sim` depends on data file `cooley.txt` generated by shell
script `TOP/tests/cooley.sh`, and generic parameter `n` must be set to
`100000`, the following can be added to, e.g., `TOP/tests/cooley.mk`:

    cooley_sim.sim: GHDLRUNOPTS += -gn=100000
    cooley_sim.sim: $$(DIR)/cooley.txt
    $$(DIR)/cooley.txt: $$(TOP)/tests/cooley.sh
            $$< > $$@
endef
export LONG_HELP_message

long-help:: help
	@printf '\n%s\n' "$$LONG_HELP_message"

clean:
	@printf '[RM]    %s\n' "$(DIR)"
	rm -rf $(TOP)$(DIR)

define INTRO_message
# Makefile for VHDL compilation and simulation

## Quick start

Drop this Makefile in the root directory of your VHDL project and always use
the `.vhd` extension for your source files. From the root directory of your
VHDL project type `make` to print the short help or `make long-help` for the
complete help.
endef
export INTRO_message

README.md: $(TOP)/Makefile $(wildcard $(TOP)/$(CONFIG))
	printf '%s\n' "$$INTRO_message" > $@
	printf '\n```\n' >> $@
	printf '%s\n' "$$HELP_message" >> $@
	printf '```\n\n## Documentation\n\n' >> $@
	printf '%s\n' "$$LONG_HELP_message" >> $@

# if not clean, help or long-help, and first make invocation
ifneq ($(filter-out clean help long-help,$(MAKECMDGOALS)),)
ifneq ($(PASS),run)

# double-colon rule in case we want to add something elsewhere (e.g. in
# design-specific files)
# last resort default rule to invoke again with same goal and same Makefile but
# in $(DIR)
%::
	mkdir -p $(TOP)$(DIR)/$(TAGS)
	$(MAKE) --no-print-directory -C $(TOP)$(DIR) -f $(TOP)/Makefile $@ PASS=run

# second make invocation (in $(DIR))
else

# search tag files in $(TAGS)
VPATH := $(TAGS)
# all source and dependency files
SRCMKS := $(shell find -L $(TOP) -type f,l \( -name '*.vhd' -o -name '*.mk' \))
# all source files
SRCS := $(patsubst $(TOP)/%,%,$(filter %.vhd,$(SRCMKS)))
# skip units listed in SKIP
SRCS := $(filter-out $(addprefix %/,$(addsuffix .vhd,$(SKIP))),$(SRCS))
# unit names (source file base names without .vhd extension)
UNITS := $(patsubst %.vhd,%,$(notdir $(SRCS)))
sorted_units := $(sort $(UNITS))
duplicates := $(sort $(strip $(foreach u,$(sorted_units),$(word 2,$(filter $u,$(UNITS))))))
ifneq ($(duplicates),)
$(error duplicated unit names: $(duplicates))
endif
UNITS := $(sorted_units)
# simulation goals are UNIT.sim
SIMULATIONS := $(addsuffix .sim,$(UNITS))
# all dependency files under $(TOP)
MKS := $(filter %.mk,$(SRCMKS))

.PHONY: units libs all $(addprefix .sim,$(UNITS))

# include dependency files
include $(MKS)

# library list
LIBS :=

# $(1): source file path relative to $(TOP)
# define target-specific variables (LIBNAME, UNIT)
# instantiate compilation and simulation rules
# in $(DIR) empty files with unit names are used to keep track of last
# compilation times
define GEN_rule
$(1)-unit := $$(patsubst %.vhd,%,$$(notdir $(1)))
ifeq ($$(MODE),work)
$$($(1)-unit)-lib ?= work
else
$$($(1)-unit)-lib ?= $$(notdir $$(patsubst %/,%,$$(dir $(1))))
endif
$$($(1)-unit) $$($(1)-unit).sim: LIBNAME = $$($$($(1)-unit)-lib)
$$($(1)-unit) $$($(1)-unit).sim: UNIT    = $$($(1)-unit)

LIBS += $$($$($(1)-unit)-lib)

$$($(1)-unit): $$(TOP)/$(1)
	@printf '[COM]   %-50s -> %s\n' "$$(patsubst $$(TOP)/%,%,$$<)" "$$(LIBNAME)"
	$$(COM)
	touch $(TAGS)/$$@

$$($(1)-unit).sim: $$($(1)-unit)
	@printf '[SIM]   %-50s\n' "$$(LIBNAME).$$(UNIT)"
	$$(ELAB)
	$$(RUN)
endef
$(foreach f,$(SRCS),$(eval $(call GEN_rule,$(f))))

# library list without duplicates
LIBS := $(sort $(LIBS))

%.wave:
	@printf '%s\n\n' "[WAVE] $*"
	echo "Opening gtkwave..."
	nohup gtkwave $(TOP)$(DIR)/$*.ghw &

# list libraries
libs:
	@printf '%s\n' $(LIBS)

# list units
units:
	@printf '%-36s%-36s\n' $(UNITS)

# compile all units
all: $(UNITS)
endif
endif

# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
