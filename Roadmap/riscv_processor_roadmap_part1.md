# RISC-V Processor Implementation Roadmap — Part 1

> **For:** B.Tech ECE Student | **Goal:** Industry-grade RISC-V processor for RTL/VLSI interviews
> **Your Current State:** Working single-cycle RV32I processor (ALU, Control, RegFile, IFU, BranchUnit, DataMem, ImmGen)

---

## Phase 1: Fundamentals Required Before Starting

> [!NOTE]
> You already have a working single-cycle processor, so you've covered many basics. This section identifies **gaps to fill** for interview readiness.

### 1.1 Digital Design Concepts (Review in 1 week)

| Topic | Why It Matters | Interview Frequency |
|-------|---------------|-------------------|
| Combinational vs Sequential logic | Foundation of all RTL | ★★★★★ |
| Blocking (`=`) vs Non-blocking (`<=`) | #1 RTL bug source | ★★★★★ |
| Setup/Hold time, metastability | Asked in every interview | ★★★★★ |
| Clock domain crossing (CDC) | Critical for real chips | ★★★★☆ |
| Latch inference & how to avoid it | Synthesis pitfall | ★★★★☆ |
| Glitch-free mux design | Shows design maturity | ★★★☆☆ |

**Key Rule:** Every `always @(*)` block must assign ALL outputs in ALL branches. Missing this creates **latches** — the #1 synthesis warning interviewers will grill you on.

### 1.2 FSM Design (Critical — 3 days)

```
Moore FSM: Output depends ONLY on current state
Mealy FSM: Output depends on current state AND inputs

Interview favorite: "Design a sequence detector for 1011 — overlapping vs non-overlapping"
```

**FSM coding template (industry-standard 3-always-block style):**
```verilog
// Block 1: State register (sequential)
always @(posedge clk or negedge rst_n)
    if (!rst_n) state <= IDLE;
    else        state <= next_state;

// Block 2: Next-state logic (combinational)
always @(*) begin
    next_state = state; // default: hold state
    case (state)
        IDLE:  if (start) next_state = RUN;
        RUN:   if (done)  next_state = IDLE;
    endcase
end

// Block 3: Output logic (combinational)
always @(*) begin
    busy = 1'b0; // default
    case (state)
        RUN: busy = 1'b1;
    endcase
end
```

### 1.3 Computer Architecture Basics (1 week)

| Concept | What to Know |
|---------|-------------|
| Von Neumann vs Harvard | Your processor uses Harvard (separate I-mem and D-mem) |
| RISC vs CISC | RISC-V is RISC: fixed-length instructions, load-store architecture |
| Pipeline concepts | 5-stage: IF → ID → EX → MEM → WB |
| Memory hierarchy | Registers → L1 Cache → L2 → Main Memory → Disk |
| CPI (Cycles Per Instruction) | Single-cycle: CPI=1 but long clock period. Pipeline: CPI≈1 with shorter clock |
| Amdahl's Law | Speedup limited by serial portion — relevant for pipeline analysis |

### 1.4 Verilog Concepts (Ongoing)

**Must-know for interviews:**
- `wire` vs `reg` — when to use each
- `always @(*)` for combinational, `always @(posedge clk)` for sequential
- `generate` blocks for parameterized design
- `localparam` and `` `define`` for constants
- `$signed()` vs unsigned operations (your ALU already uses this correctly!)
- Synthesis vs simulation constructs (what synthesizes, what doesn't)

### 1.5 Timing & Synthesis Basics (3 days)

```
Critical Path = Longest combinational delay between two flip-flops
Clock Period ≥ T_clk-to-q + T_combinational + T_setup

Your single-cycle processor's critical path:
  PC_reg → Inst_Mem → Control + RegFile → ALU → Data_Mem → RegFile_write
  (This is WHY we pipeline — to break this long path)
```

---

## Phase 2: RISC-V ISA Deep Dive

### 2.1 RV32I Instruction Formats

```
R-type: [funct7(7)] [rs2(5)] [rs1(5)] [funct3(3)] [rd(5)] [opcode(7)]
I-type: [imm[11:0](12)]       [rs1(5)] [funct3(3)] [rd(5)] [opcode(7)]
S-type: [imm[11:5](7)] [rs2(5)] [rs1(5)] [funct3(3)] [imm[4:0](5)] [opcode(7)]
B-type: [imm[12|10:5](7)] [rs2(5)] [rs1(5)] [funct3(3)] [imm[4:1|11](5)] [opcode(7)]
U-type: [imm[31:12](20)]                              [rd(5)] [opcode(7)]
J-type: [imm[20|10:1|11|19:12](20)]                   [rd(5)] [opcode(7)]
```

### 2.2 Complete RV32I Instruction Map

| Category | Instructions | Opcode | Your Status |
|----------|-------------|--------|-------------|
| R-type ALU | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | `0110011` | ✅ Done |
| I-type ALU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | `0010011` | ✅ Done |
| Load | LB, LH, LW, LBU, LHU | `0000011` | ✅ Done |
| Store | SB, SH, SW | `0100011` | ✅ Done |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | `1100011` | ✅ Done |
| JAL | JAL | `1101111` | ✅ Done |
| JALR | JALR | `1100111` | ✅ Done |
| LUI | LUI | `0110111` | ✅ Done |
| AUIPC | AUIPC | `0010111` | ✅ Done |

> [!TIP]
> Your single-cycle processor already covers the full RV32I base! This is a strong foundation. The next steps are about **architecture upgrades** and **verification depth**.

### 2.3 Key Design Decisions in Your Current Processor

**What you did right:**
- Separate `IMM_GEN` module — clean separation of concerns
- `BRANCH_UNIT` as separate module — good modularity
- Parameterized ALU control encoding
- Proper signed/unsigned handling in ALU (`$signed()`)

**What needs improvement for industry-grade:**
1. **No named port connections** — your `IFU` instantiation uses positional (fragile, error-prone)
2. **Files duplicated** across folders — should use a single source with proper include paths
3. **No `default` in case statements** inside some modules
4. **No parameterization** — memory sizes, data widths hardcoded
5. **No reset for register file** — industry requires known initial state
6. **Missing `timescale` consistency** — some files have it, some don't
7. **Using `reg` for module outputs that should be `wire`** — keep signal intent clear

---

## Phase 3: Step-by-Step Processor Implementation

### Stage 1: Single-Cycle Processor ✅ (Your Current State)

**Architecture:**
```
                    ┌─────────────────────────────────────────────────────────┐
  ┌─────┐    ┌─────┴──┐    ┌────────┐    ┌─────────┐    ┌────────┐         │
  │ PC  │───→│Inst Mem│───→│Control │───→│Reg File │───→│  ALU   │───→┌────┴───┐
  │     │    └────────┘    └────────┘    └─────────┘    └────────┘    │Data Mem│
  └──┬──┘         │            │              ↑             │         └────────┘
     │            │         IMM_GEN           │         Branch Unit        │
     │            │            │              └──────────────┴─────────────┘
     └────────────┴────────────┴──── PC+4 / Branch Target ────────────────┘
```

**Your Modules (Current):**

| Module | File | Status | Industry Gap |
|--------|------|--------|-------------|
| `PROCESSOR` | PROCESSOR.v | ✅ Working | Use named ports |
| `IFU` | IFU.v | ✅ Working | Add parameterized PC width |
| `CONTROL` | CONTROL.v | ✅ Working | Good — has defaults |
| `ALU` | ALU.v | ✅ Working | Add overflow detection |
| `REG_FILE` | REG_FILE.v | ✅ Working | Add reset, clean up `always` blocks |
| `IMM_GEN` | IMM_GEN.v | ✅ Working | Good |
| `BRANCH_UNIT` | BRANCH_UNIT.v | ✅ Working | Good modularity |
| `DATA_MEM` | DATA_MEM.v | ✅ Working | Parameterize depth |
| `INST_MEM` | INST_MEM.v | ✅ Working | Use `$readmemh` |

**Common Bugs in Single-Cycle (check yours):**
1. `x0` not hardwired to zero on writes → writing to x0 should be ignored
2. Branch target calculated incorrectly (byte vs word addressing)
3. JALR target: should be `(rs1 + imm) & ~1`, not just `rs1 + imm`
4. Store instructions: `rs2` data alignment for SB/SH
5. Sign extension errors in immediate generation

**Testing Strategy:**
```
1. Unit tests for each module individually (you have some ✅)
2. Integration test: run a small program covering all instruction types
3. RISC-V compliance tests (riscv-tests from GitHub)
4. Self-checking testbench with expected values
```

---

### Stage 2: Multi-Cycle Processor (New — Build This Next)

**Why multi-cycle?** Breaks the single long critical path into multiple shorter cycles. Each instruction takes 3-5 cycles depending on type.

**Architecture — FSM-Controlled Datapath:**

```
States: FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK

Cycle count per instruction type:
  R-type:  4 cycles (FETCH → DECODE → EXECUTE → WB)
  I-type:  4 cycles (FETCH → DECODE → EXECUTE → WB)
  Load:    5 cycles (FETCH → DECODE → EXECUTE → MEMORY → WB)
  Store:   4 cycles (FETCH → DECODE → EXECUTE → MEMORY)
  Branch:  3 cycles (FETCH → DECODE → EXECUTE)
  Jump:    3 cycles (FETCH → DECODE → EXECUTE)
```

**New Modules Required:**

| Module | Purpose |
|--------|---------|
| `MC_CONTROL` | FSM-based control unit (replaces combinational control) |
| `IR_REG` | Instruction Register — holds instruction across cycles |
| `A_REG`, `B_REG` | Temporary registers for rs1, rs2 data |
| `ALU_OUT_REG` | Holds ALU result for next cycle |
| `MDR` | Memory Data Register |

**Key Differences from Single-Cycle:**

```diff
- Control: Pure combinational logic
+ Control: FSM with state register (5-7 states)

- Memory: Separate instruction and data memories
+ Memory: Can share single memory (Harvard → Princeton possible)

- Datapath: All in one cycle
+ Datapath: Intermediate registers between stages

- CPI: Always 1
+ CPI: Average 4.0-4.5 (variable per instruction)
```

**Debugging Methods:**
1. Trace FSM state transitions in waveform
2. Verify IR holds correct instruction across cycles
3. Check temporary register values at each state transition
4. Compare final register file values with single-cycle version

---

### Stage 3: 5-Stage Pipelined Processor (The Resume Centerpiece)

**Architecture Overview:**

```
 ┌────┐  ┌──────┐  ┌────┐  ┌──────┐  ┌────┐  ┌──────┐  ┌────┐  ┌──────┐  ┌────┐
 │ IF │──│IF/ID │──│ ID │──│ID/EX │──│ EX │──│EX/MEM│──│MEM │──│MEM/WB│──│ WB │
 └────┘  └──────┘  └────┘  └──────┘  └────┘  └──────┘  └────┘  └──────┘  └────┘
   ↓                  ↓                 ↓                  ↓                 ↓
  Inst              Decode           ALU Op             Mem R/W          Reg Write
  Fetch             + RegRead        + Branch           + Cache          Back
```

**Required Verilog Modules:**

| Module | Purpose | Complexity |
|--------|---------|-----------|
| `pipeline_IF` | PC logic, instruction fetch | Low |
| `pipeline_ID` | Decode, register read, immediate gen | Medium |
| `pipeline_EX` | ALU operation, branch resolution | Medium |
| `pipeline_MEM` | Data memory read/write | Low |
| `pipeline_WB` | Write-back mux | Low |
| `IF_ID_reg` | Pipeline register IF→ID | Low |
| `ID_EX_reg` | Pipeline register ID→EX | Medium |
| `EX_MEM_reg` | Pipeline register EX→MEM | Medium |
| `MEM_WB_reg` | Pipeline register MEM→WB | Low |
| `forwarding_unit` | Data hazard resolution | High |
| `hazard_detection` | Stall logic for load-use | High |
| `branch_predictor` | Static predict-not-taken initially | Medium |

**Common Bugs in Pipelined Processor:**
1. **Forgetting to propagate control signals** through pipeline registers
2. **Write-before-read hazard** in register file (WB and ID in same cycle)
3. **Forwarding from MEM stage** missed (only forwarding from EX)
4. **Load-use hazard** not stalling correctly (1-cycle bubble needed)
5. **Branch target** calculated in wrong stage
6. **Pipeline flush** not clearing all necessary pipeline registers
7. **JAL/JALR** return address (PC+4) not propagated correctly through pipeline

**Testing Strategy for Pipeline:**
```
Test 1: No hazards — sequential independent instructions
Test 2: RAW hazard — back-to-back dependent instructions  
Test 3: Load-use hazard — load followed by dependent instruction
Test 4: Branch — test taken and not-taken paths
Test 5: JAL/JALR — test jump and link
Test 6: Mixed — realistic program with all hazard types
Test 7: RISC-V compliance tests (riscv-tests suite)
```

---

## Phase 4: Pipelining In Depth

### 4.1 Pipeline Stages Detailed

**IF (Instruction Fetch):**
```verilog
// Inputs:  PC, branch_target, stall, flush
// Outputs: instruction, PC+4
// Logic:   
//   - If stall: hold PC, hold instruction
//   - If flush: insert NOP (bubble)  
//   - Normal: PC <= PC + 4, fetch instruction from I-mem
```

**ID (Instruction Decode):**
```verilog
// Inputs:  instruction from IF/ID reg
// Outputs: rs1_data, rs2_data, immediate, control signals
// Logic:
//   - Decode opcode → generate control signals
//   - Read register file (rs1, rs2)
//   - Generate immediate value
//   - Hazard detection: check if load-use → generate stall
```

**EX (Execute):**
```verilog
// Inputs:  rs1_data, rs2_data (possibly forwarded), immediate, control
// Outputs: alu_result, branch_taken, branch_target
// Logic:
//   - Forwarding mux: select actual operand (reg, EX_fwd, MEM_fwd)
//   - ALU operation
//   - Branch condition evaluation
//   - Branch target calculation: PC + immediate
```

**MEM (Memory Access):**
```verilog
// Inputs:  alu_result (address), rs2_data (store data), control
// Outputs: mem_data, alu_result_passthrough
// Logic:
//   - Load: read data memory at alu_result address
//   - Store: write rs2_data to data memory at alu_result address
//   - Others: pass alu_result through
```

**WB (Write Back):**
```verilog
// Inputs:  alu_result, mem_data, control
// Outputs: write_data, write_addr, reg_write_enable
// Logic:
//   - Mux: select alu_result or mem_data based on mem_to_reg
//   - Write back to register file
```

### 4.2 Pipeline Registers — What Goes Through Each

```
IF/ID Register:
  ├── instruction [31:0]
  ├── PC [31:0]  
  └── PC+4 [31:0]

ID/EX Register:
  ├── rs1_data [31:0], rs2_data [31:0]
  ├── immediate [31:0]
  ├── rd [4:0], rs1_addr [4:0], rs2_addr [4:0]
  ├── PC [31:0], PC+4 [31:0]
  ├── funct3 [2:0], funct7 [6:0]
  └── Control: {alu_control, alu_src, reg_write, mem_read, 
                mem_write, mem_to_reg, branch, jump}

EX/MEM Register:
  ├── alu_result [31:0]
  ├── rs2_data [31:0]  (for store)
  ├── rd [4:0]
  ├── PC+4 [31:0]  (for JAL/JALR)
  ├── zero_flag
  └── Control: {reg_write, mem_read, mem_write, mem_to_reg, branch, jump}

MEM/WB Register:
  ├── alu_result [31:0]
  ├── mem_data [31:0]
  ├── rd [4:0]
  ├── PC+4 [31:0]
  └── Control: {reg_write, mem_to_reg}
```

### 4.3 Data Hazards & Forwarding Unit

**RAW (Read After Write) — The only real data hazard in in-order pipeline:**

```
Hazard Example:
  ADD x1, x2, x3    # writes x1 in WB (cycle 5)
  SUB x4, x1, x5    # reads x1 in ID (cycle 3) — x1 not ready!
```

**Forwarding Unit Logic:**
```verilog
// Forward from EX/MEM stage
if (EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs1)
    ForwardA = 2'b10;  // forward EX/MEM alu_result

// Forward from MEM/WB stage  
if (MEM_WB_RegWrite && MEM_WB_rd != 0 && MEM_WB_rd == ID_EX_rs1
    && !(EX_MEM_RegWrite && EX_MEM_rd != 0 && EX_MEM_rd == ID_EX_rs1))
    ForwardA = 2'b01;  // forward MEM/WB write_data

// Same logic for ForwardB (rs2)
```

**Load-Use Hazard (cannot forward — must stall):**
```
LW  x1, 0(x2)     # x1 available after MEM stage
ADD x3, x1, x4    # needs x1 in EX stage — 1 cycle too early!

Solution: Stall pipeline 1 cycle + forward from MEM/WB
```

**Hazard Detection Unit:**
```verilog
// Detect load-use hazard
if (ID_EX_MemRead && 
    (ID_EX_rd == IF_ID_rs1 || ID_EX_rd == IF_ID_rs2))
begin
    stall = 1'b1;      // freeze PC and IF/ID register
    flush_ID_EX = 1'b1; // insert bubble in ID/EX
end
```

### 4.4 Control Hazards

**Branch Resolution:**
```
Branch decided in EX stage → 2 cycles of wrong instructions fetched

Solutions (progressive complexity):
1. Always flush (2-cycle penalty per branch)     — simple, CPI ≈ 1.4
2. Predict not-taken (flush only if taken)       — CPI ≈ 1.2
3. Static predict backward-taken                 — CPI ≈ 1.1
4. Dynamic predictor (1-bit, 2-bit BHT)         — CPI ≈ 1.05
```

**Branch flush logic:**
```verilog
if (branch_taken) begin
    flush_IF_ID = 1'b1;   // kill instruction in IF/ID
    flush_ID_EX = 1'b1;   // kill instruction in ID/EX
    PC <= branch_target;   // redirect fetch
end
```

### 4.5 CPI Analysis

```
Ideal CPI:                    1.0
+ Load-use stalls:           +0.05 (assuming 5% load-use frequency)
+ Branch misprediction:      +0.10 (assuming 20% branches, 50% taken, 2-cycle penalty)
+ Structural hazards:        +0.00 (Harvard architecture avoids this)
─────────────────────────────────
Realistic CPI:               ≈ 1.15

Speedup vs single-cycle:
  Single-cycle clock = 800ps (limited by longest path)
  Pipeline clock     = 200ps (limited by slowest stage)
  Speedup = (800 × 1.0) / (200 × 1.15) ≈ 3.5x
```

---

*Continued in [Part 2](file:///C:/Users/ayush/.gemini/antigravity/brain/6eb511e4-b7bd-4c46-a258-9b862f0b6238/artifacts/riscv_processor_roadmap_part2.md) — Verilog Implementation Guide, Verification, FPGA, Advanced Extensions, Tools, Resources, Timeline, and Interview Preparation.*
