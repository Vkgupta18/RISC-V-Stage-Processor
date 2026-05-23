# 🚀 RISC-V Single-Cycle Processor

> A fully functional 32-bit single-cycle RISC-V processor implementing the **RV32I** base integer instruction set, designed in Verilog HDL.

[![Verilog](https://img.shields.io/badge/HDL-Verilog-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-green.svg)](https://riscv.org/)
[![Architecture](https://img.shields.io/badge/Architecture-Single--Cycle-orange.svg)](#architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📖 Overview

This project implements a **modular, single-cycle RISC-V processor** from the ground up in synthesizable Verilog. The processor executes one instruction per clock cycle and supports the complete RV32I base instruction set — including arithmetic, logical, memory access, branching, and jump operations.

The design follows a bottom-up development methodology: each functional unit (ALU, Register File, Control Unit, etc.) was first designed and verified independently, then integrated into the complete processor datapath.

### Key Highlights

- **Complete RV32I support** — 40+ instructions across all 6 instruction formats (R, I, S, B, U, J)
- **Modular architecture** — 10 independently testable Verilog modules
- **Automated verification** — self-checking testbench with PASS/FAIL reporting
- **Byte-addressable memory** — supports LB/LH/LW and their unsigned variants
- **Branch & jump logic** — dedicated Branch Unit with BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, JALR

---

## 🏗️ Architecture

The processor follows the classic single-cycle RISC-V datapath where all stages — Instruction Fetch, Decode, Execute, Memory Access, and Write-Back — complete within a single clock cycle.

### Block Diagram

![RISC-V Processor Architecture](images/Processor.png)

*Figure 1: Complete processor architecture showing all major components and their interconnections.*

### Datapath Flow

```
┌─────────┐    ┌──────────┐    ┌─────────┐    ┌──────────┐    ┌──────────┐
│  FETCH   │───▶│  DECODE  │───▶│ EXECUTE │───▶│  MEMORY  │───▶│WRITE-BACK│
│  (IFU)   │    │(CONTROL) │    │  (ALU)  │    │(DATA_MEM)│    │(REG_FILE)│
│          │    │(IMM_GEN) │    │         │    │          │    │          │
│          │    │(REG_FILE)│    │         │    │          │    │          │
└─────────┘    └──────────┘    └─────────┘    └──────────┘    └──────────┘
      ▲                                                             │
      └─────────────────────────────────────────────────────────────┘
                         (Branch/Jump Feedback via BRANCH_UNIT)
```

### Signal Interconnection

```
                        ┌─────────────────────────────┐
                        │        PROCESSOR.v           │
                        │       (Top-Level)            │
                        └─────────────────────────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
    ┌─────▼─────┐            ┌───────▼──────┐          ┌───────▼──────┐
    │   IFU.v   │◀──branch──▶│ BRANCH_UNIT.v│◀──alu───▶│ DATAPATH.v   │
    │           │   target   │              │  result   │              │
    │ ┌───────┐ │            └──────────────┘           │ ┌──────────┐ │
    │ │INST_  │ │                                       │ │ REG_FILE │ │
    │ │MEM.v  │ │           ┌──────────────┐            │ │          │ │
    │ └───────┘ │           │  CONTROL.v   │──signals──▶│ ├──────────┤ │
    └───────────┘           └──────┬───────┘            │ │  ALU.v   │ │
          │                        │                    │ │          │ │
          │ instruction    ┌───────▼──────┐             │ ├──────────┤ │
          └───────────────▶│  IMM_GEN.v   │──immediate─▶│ │DATA_MEM.v│ │
                           └──────────────┘             │ └──────────┘ │
                                                        └──────────────┘
```

---

## 🧩 Module Descriptions

### Top-Level: `PROCESSOR.v`

Instantiates and wires together all sub-modules. Takes only `clock` and `reset` as inputs.

---

### Instruction Fetch Unit: `IFU.v`

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clock` | Input | 1 | System clock |
| `reset` | Input | 1 | Synchronous reset |
| `branch_taken` | Input | 1 | Branch condition met |
| `jump` | Input | 1 | JAL/JALR signal |
| `branch_target` | Input | 32 | Target address |
| `Instruction_Code` | Output | 32 | Fetched instruction |
| `PC_out` | Output | 32 | Current program counter |

- Manages the **Program Counter (PC)** with automatic PC+4 increment
- Supports branch/jump target redirection
- Wraps PC at 4KB boundary (`0xFFC`)
- Instantiates `INST_MEM` for instruction storage

---

### Instruction Memory: `INST_MEM.v`

- **4 KB** byte-addressable instruction memory (`reg [7:0] Memory [0:4095]`)
- Word-aligned reads with automatic `PC[11:2]` masking
- Little-endian byte ordering
- Pre-loaded test program via `initial` block

---

### Control Unit: `CONTROL.v`

Fully combinational instruction decoder. Generates all datapath control signals from `opcode`, `funct3`, and `funct7` fields.

| Opcode | Type | Instructions |
|--------|------|-------------|
| `0110011` | R-type | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND, MUL |
| `0010011` | I-type | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI |
| `0000011` | Load | LB, LH, LW, LBU, LHU |
| `0100011` | Store | SB, SH, SW |
| `1100011` | Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU |
| `1101111` | J-type | JAL |
| `1100111` | I-type | JALR |
| `0110111` | U-type | LUI |
| `0010111` | U-type | AUIPC |

**Generated control signals:**

| Signal | Purpose |
|--------|---------|
| `alu_control[3:0]` | ALU operation select |
| `regwrite` | Enable register write-back |
| `alu_src` | ALU input2 source (0 = rs2, 1 = immediate) |
| `mem_read` | Enable data memory read |
| `mem_write` | Enable data memory write |
| `mem_to_reg` | Write-back source (0 = ALU, 1 = memory) |
| `branch` | Instruction is a branch |
| `jump` | Instruction is JAL/JALR |
| `alu_pc_src` | ALU input1 source (0 = rs1, 1 = PC for AUIPC) |

---

### Datapath: `DATAPATH.v`

Connects the Register File, ALU, and Data Memory with three key multiplexers:

1. **ALU Input1 MUX** — selects between `rs1` (default) and `PC` (for AUIPC)
2. **ALU Input2 MUX** — selects between `rs2` (R-type) and `immediate` (I/S/U-type)
3. **Write-Back MUX** — selects between `PC+4` (JAL/JALR), memory data (loads), or ALU result

---

### ALU: `ALU.v`

32-bit Arithmetic Logic Unit with 12 operations:

| ALU Control | Operation | Description |
|-------------|-----------|-------------|
| `0000` | AND | Bitwise AND |
| `0001` | OR | Bitwise OR |
| `0010` | ADD | Addition |
| `0011` | SLL | Shift Left Logical |
| `0100` | SUB | Subtraction |
| `0101` | SRL | Shift Right Logical |
| `0110` | MUL | Multiplication |
| `0111` | XOR | Bitwise XOR |
| `1000` | SLT | Set Less Than (signed) |
| `1001` | SLTU | Set Less Than (unsigned) |
| `1010` | SRA | Shift Right Arithmetic |
| `1011` | PASS B | Pass-through input2 (for LUI) |

Outputs a **zero flag** when `alu_result == 0`, used by the Branch Unit for BEQ/BNE evaluation.

---

### Register File: `REG_FILE.v`

- **32 × 32-bit** general-purpose register array
- **x0 hardwired to zero** — reads always return 0, writes are ignored
- **Dual read ports** (combinational) + **single write port** (positive-edge triggered)
- Registers initialized to `reg[i] = i` on reset for testing convenience

---

### Immediate Generator: `IMM_GEN.v`

Extracts and sign-extends the immediate field from each instruction format:

| Format | Immediate Bits | Used By |
|--------|---------------|---------|
| I-type | `inst[31:20]` | ADDI, SLTI, loads, JALR |
| S-type | `inst[31:25], inst[11:7]` | SB, SH, SW |
| B-type | `inst[31], inst[7], inst[30:25], inst[11:8], 0` | BEQ, BNE, BLT, BGE |
| U-type | `inst[31:12], 12'b0` | LUI, AUIPC |
| J-type | `inst[31], inst[19:12], inst[20], inst[30:21], 0` | JAL |

---

### Branch Unit: `BRANCH_UNIT.v`

Dedicated unit for branch condition evaluation and target address calculation:

- **Branch target**: `PC + immediate` for JAL and B-type instructions
- **JALR target**: `(rs1 + immediate) & ~1` (LSB cleared per RISC-V spec)
- Evaluates all 6 branch conditions using ALU result and zero flag

---

### Data Memory: `DATA_MEM.v`

- **256 bytes** of byte-addressable data memory (`reg [7:0] memory [0:255]`)
- Little-endian byte ordering
- Supports all load/store widths via `funct3`:

| funct3 | Load | Store |
|--------|------|-------|
| `000` | LB (sign-extended) | SB |
| `001` | LH (sign-extended) | SH |
| `010` | LW | SW |
| `100` | LBU (zero-extended) | — |
| `101` | LHU (zero-extended) | — |

---

## 🧪 Verification

### Testbench: `Processor_tb.v`

The testbench runs a hardcoded test program and performs **automated verification** with PASS/FAIL reporting:

**Test Program:**
```
Addr  Instruction             Description
────  ───────────────────────  ──────────────────────────────
0x00  ADDI x5, x0, 10         x5 = 10
0x04  ADDI x6, x0, 20         x6 = 20
0x08  ADD  x7, x5, x6         x7 = 30  (10 + 20)
0x0C  SW   x7, 0(x0)          mem[0] = 30
0x10  LW   x8, 0(x0)          x8 = mem[0] = 30
0x14  BEQ  x5, x5, +8         branch taken (skip next)
0x18  ADDI x9, x0, 99         ← SKIPPED by branch
0x1C  ADDI x10, x0, 42        x10 = 42
```

**Verified Results:**

| Test | Instruction | Expected | Status |
|------|-------------|----------|--------|
| ADDI | `x5 = 10` | `0x0000000A` | ✅ PASS |
| ADDI | `x6 = 20` | `0x00000014` | ✅ PASS |
| ADD  | `x7 = 30` | `0x0000001E` | ✅ PASS |
| SW/LW | `x8 = 30` | `0x0000001E` | ✅ PASS |
| BEQ  | `x10 = 42` (x9 ≠ 99) | `0x0000002A` | ✅ PASS |

### Simulation Waveform

![Processor Waveform](images/Waveform.png)

*Figure 2: GTKWave output showing instruction execution, PC progression, and register write-back.*

---

## 🚀 Getting Started

### Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| [Icarus Verilog](http://iverilog.icarus.com/) | Compilation & simulation | `apt install iverilog` / `brew install icarus-verilog` / [Windows binary](http://bleyer.org/icarus/) |
| [GTKWave](http://gtkwave.sourceforge.net/) | Waveform viewing | `apt install gtkwave` / `brew install gtkwave` |

> Alternatively, you can use **ModelSim**, **Vivado**, or any Verilog simulator.

### Clone & Run

```bash
# Clone the repository
git clone https://github.com/Vkgupta18/RISC-V-Processor.git
cd RISC-V-Processor

# Navigate to the integrated processor
cd Processor

# Compile (all modules are `include-d from Processor_tb.v)
iverilog -o processor_sim Processor_tb.v

# Run simulation
vvp processor_sim

# View waveforms
gtkwave output_wave.vcd
```

### Testing Individual Modules

```bash
# ALU unit test
cd ALU
iverilog -o alu_sim ALU_testbench.v
vvp alu_sim

# Register File unit test
cd "Register file"
iverilog -o regfile_sim "Register File_tb.v"
vvp regfile_sim

# Datapath integration test
cd Datapath
iverilog -o datapath_sim Datapath_tb.v
vvp datapath_sim
```

---

## 📁 Project Structure

```
RISC-V-Processor/
├── README.md
│
├── Processor/                     # ── Complete Integrated Processor ──
│   ├── PROCESSOR.v                #    Top-level module
│   ├── Processor_tb.v             #    Self-checking testbench
│   ├── IFU.v                      #    Instruction Fetch Unit
│   ├── INST_MEM.v                 #    Instruction Memory (4 KB)
│   ├── CONTROL.v                  #    Control Unit / Instruction Decoder
│   ├── DATAPATH.v                 #    Datapath (MUXes + wiring)
│   ├── REG_FILE.v                 #    Register File (32 × 32-bit)
│   ├── ALU.v                      #    Arithmetic Logic Unit
│   ├── IMM_GEN.v                  #    Immediate Generator
│   ├── BRANCH_UNIT.v              #    Branch Condition Evaluator
│   ├── DATA_MEM.v                 #    Data Memory (256 bytes)
│   ├── VERIFICATION_REPORT.txt    #    Test results summary
│   └── output_wave.vcd            #    Simulation waveforms
│
├── ALU/                           # ── Standalone ALU Tests ──
│   ├── ALU.v
│   └── ALU_testbench.v
│
├── Control Unit/                  # ── Standalone Control Unit ──
│   └── CONTROL.v
│
├── Register file/                 # ── Standalone Register File Tests ──
│   ├── REG_FILE.v
│   └── Register File_tb.v
│
├── Instruction Fetch Unit/        # ── Standalone IFU Tests ──
│   ├── IFU.v
│   ├── IFU_tb.v
│   ├── INST_MEM.v
│   └── INST_MEM_tb.v
│
├── Datapath/                      # ── Standalone Datapath Tests ──
│   ├── DATAPATH.v
│   └── Datapath_tb.v
│
├── Roadmap/                       # ── Development Roadmap ──
│   ├── riscv_processor_roadmap_part1.md
│   ├── riscv_processor_roadmap_part2.md
│   └── riscv_processor_roadmap_part3.md
│
└── images/                        # ── Documentation Assets ──
    ├── Processor.png              #    Architecture block diagram
    ├── Waveform.png               #    Simulation waveform capture
    └── RISCV.png                  #    RISC-V reference image
```

---

## 🔮 Roadmap

### ✅ Phase 1 — Single-Cycle Processor (Complete)
- [x] RV32I base instruction set (R, I, S, B, U, J types)
- [x] Immediate Generator for all formats
- [x] Byte-addressable Data Memory with LB/LH/LW support
- [x] Branch Unit with all 6 branch conditions + JAL/JALR
- [x] AUIPC and LUI upper-immediate support
- [x] Automated testbench with PASS/FAIL verification

### 🔜 Phase 2 — Assembly-Based Testing
- [ ] Use RISC-V GNU Toolchain to assemble programs
- [ ] Load programs via `$readmemh` from hex files
- [ ] Build a comprehensive compliance test suite
- [ ] Self-checking testbenches with expected value tables

### 🔜 Phase 3 — 5-Stage Pipelined Processor
- [ ] Pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
- [ ] Hazard Detection Unit (stall on load-use hazards)
- [ ] Data Forwarding / Bypassing Unit
- [ ] Branch Prediction (static → dynamic)
- [ ] Pipeline flush on mispredicted branches

### 🔜 Phase 4 — ISA Extensions
- [ ] **M Extension** — Integer multiply/divide (MUL, DIV, REM)
- [ ] **Zicsr Extension** — Control & Status Registers
- [ ] Exception & interrupt handling
- [ ] Privilege levels (Machine mode)

### 🔜 Phase 5 — Memory Hierarchy & Peripherals
- [ ] Instruction & Data Caches
- [ ] Memory-Mapped I/O (UART, GPIO, Timer)
- [ ] FPGA synthesis targeting Xilinx / Intel FPGAs

---

## 🎯 Design Decisions

| Decision | Rationale |
|----------|-----------|
| Single-cycle first | Learn the fundamentals before optimizing with pipelining |
| Separate Branch Unit | Clean separation of concerns; branch logic isolated from ALU |
| Byte-addressable memory | Matches RISC-V specification; supports LB/LH/LW natively |
| `include`-based integration | Simple compilation — `iverilog Processor_tb.v` compiles everything |
| Hardcoded test program | Quick iteration during development; hex-file loading planned next |
| x0 hardwired in reads *and* writes | Belt-and-suspenders — reads return 0, writes to x0 are also blocked |

---

## 📚 References

- [RISC-V ISA Specification (Volume 1)](https://riscv.org/technical/specifications/) — The official unprivileged spec
- [Computer Organization and Design: RISC-V Edition](https://www.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-812275-4) — Patterson & Hennessy
- [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) — Cross-compiler for RISC-V
- [RISC-V ISA Simulator (Spike)](https://github.com/riscv-software-src/riscv-isa-sim) — Reference simulator

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2025 Vinit Kumar Gupta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

**⭐ If you find this project useful, please consider giving it a star! ⭐**

Made with ❤️ and Verilog

</div>