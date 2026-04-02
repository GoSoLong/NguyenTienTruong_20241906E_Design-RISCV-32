# ============================================================
# sim.tcl - QuestaSim Simulation Script
# RISC-V 5-Stage Pipeline
# Usage: vsim -do sim.tcl
# ============================================================

# Create work library
vlib work
vmap work work

# Compile all Verilog sources (order matters for dependencies)
vlog -work work PipelineRegs.v
vlog -work work IMEM.v
vlog -work work DMEM.v
vlog -work work RegFile.v
vlog -work work ImmGen.v
vlog -work work ALU.v
vlog -work work BranchComp.v
vlog -work work ControlUnit.v
vlog -work work ForwardUnit.v
vlog -work work HazardDetect.v
vlog -work work TopLevel.v
vlog -work work tb_TopLevel.v

# Start simulation
vsim -t 1ns -novopt work.tb_TopLevel

# ============================================================
# Add waveforms
# ============================================================
add wave -divider "Clock & Reset"
add wave -radix bin  /tb_TopLevel/clk
add wave -radix bin  /tb_TopLevel/rst

add wave -divider "--- IF Stage ---"
add wave -radix hex  /tb_TopLevel/dut/pc
add wave -radix hex  /tb_TopLevel/dut/inst_if

add wave -divider "--- IF/ID Register ---"
add wave -radix hex  /tb_TopLevel/dut/pc_id
add wave -radix hex  /tb_TopLevel/dut/inst_id

add wave -divider "--- ID Stage ---"
add wave -radix unsigned /tb_TopLevel/dut/rs1_id
add wave -radix unsigned /tb_TopLevel/dut/rs2_id
add wave -radix unsigned /tb_TopLevel/dut/rd_id
add wave -radix hex  /tb_TopLevel/dut/data_a_id
add wave -radix hex  /tb_TopLevel/dut/data_b_id
add wave -radix hex  /tb_TopLevel/dut/imm_id

add wave -divider "--- Control Signals ---"
add wave -radix bin  /tb_TopLevel/dut/pc_sel_id
add wave -radix bin  /tb_TopLevel/dut/a_sel_id
add wave -radix bin  /tb_TopLevel/dut/b_sel_id
add wave -radix hex  /tb_TopLevel/dut/alu_sel_id
add wave -radix bin  /tb_TopLevel/dut/mem_rw_id
add wave -radix bin  /tb_TopLevel/dut/wb_sel_id
add wave -radix bin  /tb_TopLevel/dut/reg_wen_id

add wave -divider "--- EX Stage ---"
add wave -radix unsigned /tb_TopLevel/dut/rd_ex
add wave -radix hex  /tb_TopLevel/dut/alu_a
add wave -radix hex  /tb_TopLevel/dut/alu_b
add wave -radix hex  /tb_TopLevel/dut/alu_result_ex
add wave -radix bin  /tb_TopLevel/dut/fwd_a
add wave -radix bin  /tb_TopLevel/dut/fwd_b

add wave -divider "--- MEM Stage ---"
add wave -radix unsigned /tb_TopLevel/dut/rd_mem
add wave -radix hex  /tb_TopLevel/dut/alu_mem
add wave -radix bin  /tb_TopLevel/dut/mem_rw_mem
add wave -radix hex  /tb_TopLevel/dut/mem_data_out

add wave -divider "--- WB Stage ---"
add wave -radix unsigned /tb_TopLevel/dut/rd_wb
add wave -radix hex  /tb_TopLevel/dut/wb_data
add wave -radix bin  /tb_TopLevel/dut/reg_wen_wb

add wave -divider "--- Hazard/Stall ---"
add wave -radix bin  /tb_TopLevel/dut/stall
add wave -radix bin  /tb_TopLevel/dut/flush_if_id
add wave -radix bin  /tb_TopLevel/dut/flush_id_ex

# Run simulation
run -all

# Zoom to fit waveform
wave zoom full
