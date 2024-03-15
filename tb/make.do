vlib work

vlog -sv ../rtl/ast_dmx.sv
vlog -sv ast_interface.sv
vlog -sv packages/usr_types_and_params.sv
vlog -sv packages/tb_env.sv
vlog -sv top_tb.sv

vsim -novopt top_tb
add log -r /*
add wave -r *
run -all