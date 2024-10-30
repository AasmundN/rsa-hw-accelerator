# default goal
.DEFAULT_GOAL := help

# phony targets
.PHONY: help config clean

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
SIM ?= ghdl
# GUI mode
GUI ?= no
ifneq ($(GUI),yes)
ifneq ($(GUI),no)
$(error "$(GUI): invalid GUI value")
endif
endif

GHDLAFLAGS ?= --std=08 -frelaxed --workdir=$(TOP)/$(DIR) -Wno-hide -Wno-shared
GHDLRFLAGS ?= --std=08 -frelaxed --workdir=$(TOP)/$(DIR) -Wno-hide -Wno-shared
GHDLRUNOPTS ?=

ifeq ($(SIM),ghdl)
    COM = @ghdl -a $(GHDLAFLAGS) --work=$(LIBNAME) $<
	SYNT = ghdl --synth $(GHDLRFLAGS) --out=none $(UNIT)
	SCHEMA = yosys -m ghdl -p \
			"ghdl $(GHDLRFLAGS) $(UNIT); show -stretch -width -format dot -prefix $(TOP)/$(DIR)/$(UNIT)"

    ifeq ($(GUI),yes)
        RUN = ghdl -r $(GHDLRFLAGS) $(UNIT) $(GHDLRUNOPTS) --wave=$(UNIT).ghw; \
              printf '\nGHW file: %s.ghw\n' '$(DIR)/$(UNIT)'
    else
        RUN = ghdl -r $(GHDLRFLAGS) $(UNIT) $(GHDLRUNOPTS)
    endif
else
    $(error "$(SIM): invalid SIM value")
endif

# temporary build directory
DIR ?= /tmp/$(USER)/$(PROJECT)/$(SIM)
# tags sub-directory of DIR
TAGS := .tags

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
    make foo_sim DIR=/tmp/mysim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable         valid values    description
    DIR          -               temporary build directory
    GHDLAFLAGS   -               GHDL analysis options
    GHDLRFLAGS   -               GHDL simulation options
    GHDLRUNOPTS  -               GHDL RUNOPTS options
    GUI          yes|no          use Graphical User Interface
    SKIP         -               UNITs to ignore for compilation
    V            0|1             verbosity level

Goals:
    help                         this help (default goal)
    config                       list current config values
    libs                         print library names
    UNIT                         compile UNIT.vhd
    units                        print existing UNITs not in SKIP
    all                          compile all source files not in SKIP
    UNIT.sim                     simulate UNIT, also runs synthesis test for DUT
    UNIT.wave                    view UNIT waveform using gtkwave
    UNIT.schema                  generate and open preview of unit schematics
    UNIT.synth                   check that UNIT is synthesizable
    clean                        delete temporary build directory
endef
export HELP_message

define CONFIG_values
Variable           current value
    DIR            $(DIR)
    MODE           $(MODE)
    GHDLAFLAGS     $(GHDLAFLAGS)
    GHDLRFLAGS     $(GHDLRFLAGS)
    GHDLRUNOPTS    $(GHDLRUNOPTS)
    GUI            $(GUI)
    SKIP           $(SKIP)
    V              $(V)
endef
export CONFIG_values

help::
	@printf '%s\n' "$$HELP_message"

config::
	@printf '%s\n' "$$CONFIG_values"

clean:
	@printf '[RM]    %s\n' "$(DIR)"
	rm -rf $(TOP)/$(DIR)


# if not clean or help, and first make invocation
ifneq ($(filter-out clean help ,$(MAKECMDGOALS)),)
ifneq ($(PASS),run)

# double-colon rule in case we want to add something elsewhere (e.g. in
# design-specific files)
# last resort default rule to invoke again with same goal and same Makefile but
# in $(DIR)
%::
	mkdir -p $(TOP)/$(DIR)/$(TAGS)
	$(MAKE) --no-print-directory -C $(TOP)/$(DIR) -f $(TOP)/Makefile $@ PASS=run

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

# source and test files
PROJECT_FILES := $(filter-out lib/%, $(SRCS))

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

.PHONY: units libs all $(addprefix .schema,$(UNITS)) $(addprefix .sim,$(UNITS)) $(addprefix .synth,$(UNITS)) $(addprefix .wave,$(UNITS))

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

$$($(1)-unit) $$($(1)-unit).sim $$($(1)-unit).schema $$($(1)-unit).synth: LIBNAME = $$($$($(1)-unit)-lib)
$$($(1)-unit) $$($(1)-unit).sim $$($(1)-unit).schema $$($(1)-unit).synth: UNIT    = $$($(1)-unit)

LIBS += $$($$($(1)-unit)-lib)

$$($(1)-unit): $$(TOP)/$(1)
	@printf '[COMPILE]        %-70s -> %s\n' "$$(patsubst $$(TOP)/%,%,$$<)" "$$(LIBNAME)"
	$$(COM)
	touch $(TAGS)/$$@

$$($(1)-unit).sim: all
	printf '[SIMULATE]        %-70s\n\n' "$$(LIBNAME).$$(UNIT)"
	$$(RUN)

$$($(1)-unit).synth: all
	@printf '[SYNTHESIS]    %-70s\n\n' "$$(LIBNAME).$$(UNIT)"
	$$(SYNT)

$$($(1)-unit).schema: all
	@printf '[SCHEMATIC]    %-70s\n' "$$(LIBNAME).$$(subst _tb, ,$$(UNIT))"
	@printf '\nRemoving old .dot and .svg files\n'
	@mkdir -p $$(TOP)/$$(DIR)/schema
	@rm -f $$(TOP)/$$(DIR)/schema/*.svg $$(TOP)/$$(DIR)/schema/*.dot
	$$(SCHEMA)
	dot -Tsvg -O $$(TOP)/$$(DIR)/$$(UNIT).dot
	@mv *.svg schema/
	@mv *.dot schema/
	@printf '\n[SCHEMATIC]    Schematics generated in output directory\n'

endef
$(foreach f,$(SRCS),$(eval $(call GEN_rule,$(f))))

# library list without duplicates
LIBS := $(sort $(LIBS))

# list libraries
libs:
	@printf '%s\n' $(LIBS)

# list units
units:
	@printf '%-40s%-40s\n' $(UNITS)

%.wave: 
	@printf '\n[WAVE]    %-70s\n' "$(subst .wave,.ghw,$@)"
	nohup gtkwave $(TOP)/$(DIR)/$(subst .wave,.ghw,$@) &

format:
	$(foreach file,$(PROJECT_FILES),echo; vsg -c $(TOP)/vsg_config.json -f $(TOP)/$(file) --fix;)


# compile all units
all: $(UNITS)
endif
endif


# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
