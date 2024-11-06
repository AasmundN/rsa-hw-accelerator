
cd [file dirname [file normalize [info script]]]
set origin_dir "."

#include useful procedures
source -notrace [file normalize "${origin_dir}/../procedures.tcl"]

# Set the project name
set _xil_proj_name_ "rsa-hw-accelerator"
#top level design module
set top_design "rsa_core"
#top leves simulation module
set top_design_testbench ${top_design}
#directory for user IPs
set IP_directory ""


#source for to be included in synthesis
set source_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/"] -type f *] \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/modexp/"] -type f *] \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/monpro/"] -type f *] \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/source/shared/"] -type f *] \
	{*}[include_from_file $origin_dir [file normalize "$origin_dir/include.txt"]] \
]

#source file to be only included in simulation
set sim_files [list \
	{*}[glob -nocomplain -directory [file normalize "$origin_dir/testbench/"] -type f *]\
]

genProj $_xil_proj_name_ $top_design $top_design_testbench $source_files $sim_files $IP_directory
