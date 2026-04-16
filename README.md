# RISC-V 5-Stage Pipelined Processor — Verilog
## CS61C Reference Card Datapath Implementation

---

## Project Structure

```
riscv_pipeline/
├── IMEM.v           # Instruction Memory (IF stage)
├── DMEM.v           # Data Memory (MEM stage)
├── RegFile.v        # Register File (ID/WB stage)
├── ImmGen.v         # Immediate Generator (ID stage)
├── ALU.v            # Arithmetic Logic Unit (EX stage)
├── BranchComp.v     # Branch Comparator (ID stage)
├── ControlUnit.v    # Main Control Unit (ID stage)
├── ForwardUnit.v    # Data Forwarding Unit
├── HazardDetect.v   # Hazard Detection Unit
├── PipelineRegs.v   # IF/ID, ID/EX, EX/MEM, MEM/WB registers
├── TopLevel.v       # Top-level pipeline (all stages connected)
├── tb_TopLevel.v    # QuestaSim Testbench
├── program.hex      # Test program (hex encoded)
└── sim.tcl          # QuestaSim TCL run script
```

---

## Pipeline Stages

```
 ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
 │  IF  │→  │  ID  │→  │  EX  │→  │ MEM  │→  │  WB  │
 │ IMEM │   │  RF  │   │ ALU  │   │ DMEM │   │  RF  │
 └──────┘   │  CU  │   │ Fwd  │   └──────┘   └──────┘
            │ Imm  │   └──────┘
            │ Br.C │
            └──────┘
```

| Stage | Modules                         | Pipeline Reg |
|-------|---------------------------------|--------------|
| IF    | IMEM, PC                        | IF/ID        |
| ID    | RegFile, ControlUnit, ImmGen, BranchComp | ID/EX |
| EX    | ALU, ForwardUnit                | EX/MEM       |
| MEM   | DMEM                            | MEM/WB       |
| WB    | RegFile write-back              | —            |

---

## Hazard Handling

### Data Hazards — Forwarding Unit
| Hazard Type   | Source → Dest | Forwarding Path     |
|---------------|---------------|---------------------|
| EX-EX hazard  | EX → EX       | MEM stage → ALU input |
| MEM-EX hazard | MEM → EX      | WB stage → ALU input  |

### Load-Use Hazard — Stall (HazardDetect)
When a LOAD is in EX and the next instruction needs its result:
- PC is **frozen** (stall)
- IF/ID register is **frozen**
- ID/EX register is **flushed** → bubble/NOP inserted

### Control Hazards — Flush (HazardDetect)
Branch resolution in ID stage (early branch):
- If branch/JAL/JALR taken → **flush IF/ID** (1-cycle penalty)

---

## Control Signals

| Signal   | Bits | Meaning                              |
|----------|------|--------------------------------------|
| PCSel    | 2    | 00=PC+4, 01=branch/JAL, 10=JALR     |
| ImmSel   | 3    | 000=I, 001=S, 010=B, 011=U, 100=J   |
| ASel     | 1    | 0=Reg[rs1], 1=PC                     |
| BSel     | 1    | 0=Reg[rs2], 1=Imm                    |
| ALUSel   | 4    | See ALU.v encoding table             |
| MemRW    | 2    | 00=none, 01=read, 10=write           |
| WBSel    | 2    | 00=ALU, 01=Mem, 10=PC+4              |
| RegWEn   | 1    | 1=write register file                |

---

## How to Run in QuestaSim

```tcl
# Option 1: Run TCL script directly
vsim -do sim.tcl

# Option 2: Manual compile + simulate
vlib work
vlog PipelineRegs.v IMEM.v DMEM.v RegFile.v ImmGen.v \
     ALU.v BranchComp.v ControlUnit.v ForwardUnit.v \
     HazardDetect.v TopLevel.v tb_TopLevel.v
vsim work.tb_TopLevel
run -all
```

---

## Test Program (program.hex)

```asm
addi x1, x0, 5      # x1  = 5
addi x2, x0, 3      # x2  = 3
add  x3, x1, x2     # x3  = 8   ← EX-EX forward
sub  x4, x3, x2     # x4  = 5   ← EX-EX forward
sw   x3, 0(x0)      # mem[0] = 8
lw   x5, 0(x0)      # x5  = 8   ← load-use stall
add  x6, x5, x1     # x6  = 13  ← MEM-EX forward
addi x7, x0, 8      # x7  = 8
beq  x3, x7, +8     # branch taken (x3==x7==8) ← flush test
addi x8, x0, 99     # FLUSHED (never commits)
addi x9, x0, 42     # x9  = 42  ← branch target
and  x11,x1, x2     # x11 = 1
or   x12,x1, x2     # x12 = 7
xor  x13,x1, x2     # x13 = 6
slt  x14,x2, x1     # x14 = 1
```

### Expected Register Results
| Register | Expected Value |
|----------|---------------|
| x1       | 5             |
| x2       | 3             |
| x3       | 8             |
| x4       | 5             |
| x5       | 8             |
| x6       | 13            |
| x7       | 8             |
| x8       | 0 (flushed)   |
| x9       | 42            |
| x11      | 1             |
| x12      | 7             |
| x13      | 6             |
| x14      | 1             |

---

## Supported Instructions

**R-type:** add, sub, and, or, xor, sll, srl, sra, slt, sltu, mul  
**I-type:** addi, andi, ori, xori, slli, srli, srai, slti, sltiu  
**Load:** lb, lbu, lh, lhu, lw  
**Store:** sb, sh, sw  
**Branch:** beq, bne, blt, bge, bltu, bgeu  
**Jump:** jal, jalr  
**Upper:** lui, auipc  
**System:** ecall, ebreak (NOP)
