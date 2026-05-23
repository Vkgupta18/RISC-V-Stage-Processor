# RISC-V Processor Implementation Roadmap — Part 3

> Continuation from [Part 2](file:///C:/Users/ayush/.gemini/antigravity/brain/6eb511e4-b7bd-4c46-a258-9b862f0b6238/artifacts/riscv_processor_roadmap_part2.md)

---

## Phase 9: Recommended Tools & Workflow

### 9.1 Tool Stack

| Tool | Purpose | Install |
|------|---------|---------|
| **Icarus Verilog** | Simulation (Verilog) | `choco install iverilog` (Windows) |
| **Verilator** | Fast sim + **lint checking** | WSL: `sudo apt install verilator` |
| **GTKWave** | Waveform viewer | `choco install gtkwave` |
| **Vivado** (Free WebPACK) | FPGA synthesis + simulation | Xilinx website (large download) |
| **ModelSim Intel Ed.** | Industry-standard sim | Intel FPGA website (free) |
| **RISC-V GNU Toolchain** | Compile C/assembly to RV32I | Build from source or prebuilt |
| **VS Code + Verilog ext** | Code editing with syntax | Install "Verilog-HDL" extension |
| **Git + GitHub** | Version control | Essential for portfolio |

### 9.2 Makefile for Automation

```makefile
# Makefile for RISC-V Processor simulation
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
VERILATOR = verilator

RTL_DIR = rtl
TB_DIR = tb
SIM_DIR = sim

# Source files
RTL_SRC = $(wildcard $(RTL_DIR)/core/*.v) \
          $(wildcard $(RTL_DIR)/pipeline/*.v) \
          $(wildcard $(RTL_DIR)/hazard/*.v) \
          $(wildcard $(RTL_DIR)/memory/*.v)

# Compile and simulate
sim: $(RTL_SRC) $(TB_DIR)/tb_riscv_top.v
	$(IVERILOG) -o $(SIM_DIR)/sim.vvp $(RTL_SRC) $(TB_DIR)/tb_riscv_top.v
	$(VVP) $(SIM_DIR)/sim.vvp

# View waveforms
wave:
	$(GTKWAVE) $(SIM_DIR)/wave.vcd

# Lint check with Verilator
lint:
	$(VERILATOR) --lint-only -Wall $(RTL_SRC)

# Run all tests
test: test_alu test_branch test_hazard test_compliance

test_alu:
	$(IVERILOG) -o $(SIM_DIR)/alu.vvp $(RTL_SRC) $(TB_DIR)/tb_alu.v
	$(VVP) $(SIM_DIR)/alu.vvp

clean:
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd

.PHONY: sim wave lint test clean
```

### 9.3 Git Workflow

```bash
# Branch strategy
main          ← stable, tested, demo-ready
├── dev       ← active development
├── feature/pipeline     ← pipeline implementation
├── feature/forwarding   ← forwarding unit
├── feature/cache        ← cache (future)
└── fix/branch-hazard    ← bug fixes

# Commit message style
git commit -m "feat(pipeline): add EX/MEM pipeline register with flush support"
git commit -m "fix(forwarding): handle MEM-to-EX forwarding priority"
git commit -m "test(hazard): add load-use hazard test program"
git commit -m "docs: update architecture diagram with forwarding paths"
```

---

## Phase 10: Learning Resources

### 10.1 Books (Priority Order)

| # | Book | Author | Why |
|---|------|--------|-----|
| 1 | **Computer Organization & Design: RISC-V Edition** | Patterson & Hennessy | THE bible — covers single-cycle through pipeline with RISC-V |
| 2 | **Digital Design & Computer Architecture: RISC-V Edition** | Harris & Harris | More hardware-focused, excellent diagrams |
| 3 | **The RISC-V Reader** | Patterson & Waterman | Quick ISA reference (short, free online) |
| 4 | **Verilog HDL** | Samir Palnitkar | Best Verilog reference |
| 5 | **SystemVerilog for Verification** | Chris Spear | For verification skills |

### 10.2 YouTube Playlists

| Channel | Playlist | Topics |
|---------|----------|--------|
| **Onur Mutlu (ETH Zürich)** | Computer Architecture lectures | Best architecture lectures globally |
| **NPTEL — IIT Madras** | Computer Organization | Indian context, thorough |
| **Neso Academy** | Digital Electronics | Fundamentals review |
| **ChipVerify (website)** | SV/UVM tutorials | Verification gold standard |
| **Robert Baruch** | "Building a RISC-V CPU" | Step-by-step processor build |
| **Ben Eater** | "Building an 8-bit computer" | Intuition for datapath design |

### 10.3 Best GitHub Repositories to Study

| Repository | What You'll Learn |
|------------|------------------|
| [**riscv/riscv-tests**](https://github.com/riscv-software-src/riscv-tests) | Official compliance tests — run these on YOUR processor |
| [**PicoRV32**](https://github.com/YosysHQ/picorv32) | Size-optimized RV32I — study for area-efficient design |
| [**SERV**](https://github.com/olofk/serv) | World's smallest RISC-V — bit-serial architecture |
| [**VexRiscv**](https://github.com/SpinalHDL/VexRiscv) | Highly configurable pipeline — study plugin architecture |
| [**Ibex (lowRISC)**](https://github.com/lowRISC/ibex) | Google-backed, production-quality — study coding style |
| [**NEORV32**](https://github.com/stnolting/neorv32) | Full SoC with peripherals — study for FPGA implementation |
| [**Rocket Chip**](https://github.com/chipsalliance/rocket-chip) | UC Berkeley's in-order pipeline — advanced reference |

> [!TIP]
> **Ibex (lowRISC)** is the single best core to study for industry coding style. It's written in SystemVerilog with proper lint, assertions, and documentation. Read its `ibex_core.sv` and `ibex_alu.sv`.

### 10.4 Key Blogs & References

- [**RISC-V Specifications**](https://riscv.org/technical/specifications/) — Official ISA spec (read Vol 1, Ch 2 & 24)
- [**Five Easy Pieces (Patterson)**](https://www.youtube.com/watch?v=RVGeVVwuj2w) — Original RISC-V motivation talk
- [**HDLBits**](https://hdlbits.01xz.net/) — Interactive Verilog practice (do ALL problems)
- [**chipverify.com**](https://www.chipverify.com/) — SV/UVM reference

---

## Phase 11: Project Milestones & Timeline

### 11.1 Realistic Schedule (for a 4th-year student with 3-4 hours/day)

```
Week 1-2:   Foundation review + code cleanup
Week 3-4:   Multi-cycle processor
Week 5-8:   Pipelined processor (basic, no hazards)
Week 9-10:  Forwarding unit + hazard detection
Week 11-12: Branch handling + compliance tests
Week 13-14: FPGA synthesis + UART debug
Week 15-16: Documentation + resume polish
Week 17-20: Advanced extensions (CSR, RV32M, cache)
```

### 11.2 Detailed Weekly Milestones

#### Weeks 1-2: Code Cleanup & Foundation

| Day | Task | Deliverable |
|-----|------|-------------|
| 1-2 | Restructure folders to industry layout | New `rtl/`, `tb/`, `sim/` structure |
| 3-4 | Switch to named port connections everywhere | All modules use `.port(signal)` style |
| 5-6 | Add `riscv_defs.vh` header with constants | Shared `` `define`` constants across modules |
| 7-8 | Create Makefile, lint-clean with Verilator | Zero lint warnings |
| 9-10 | Write self-checking testbench | PASS/FAIL output for single-cycle |
| 11-14 | Load RISC-V assembly test programs via `$readmemh` | 5+ test hex files |

**Resume after this:** *"Designed RV32I single-cycle processor in Verilog with lint-clean RTL and automated testing"*

#### Weeks 3-4: Multi-Cycle Processor

| Task | Details |
|------|---------|
| Design FSM controller | 5-state FSM (FETCH, DECODE, EXECUTE, MEMORY, WB) |
| Add intermediate registers | IR, A, B, ALU_OUT, MDR |
| Modify datapath | Shared memory bus, mux additions |
| Test thoroughly | Same programs as single-cycle, verify same results |

**Resume after this:** *"Implemented both single-cycle and multi-cycle architectures for CPI comparison"*

#### Weeks 5-8: Basic Pipeline

| Week | Focus |
|------|-------|
| 5 | Design pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) |
| 6 | Connect stages, propagate control signals |
| 7 | Test with NOP-separated programs (no hazards) |
| 8 | Debug, waveform analysis, fix timing issues |

**Resume after this:** *"Built 5-stage pipelined RISC-V processor"*

#### Weeks 9-10: Hazard Resolution

| Task | Details |
|------|---------|
| Forwarding unit | EX-to-EX and MEM-to-EX forwarding paths |
| Hazard detection | Load-use detection with pipeline stall |
| Testing | Programs specifically designed to trigger each hazard type |
| CPI measurement | Count cycles vs instructions, compute actual CPI |

**Resume after this:** *"Implemented data forwarding and hazard detection, achieving CPI of 1.15"*

#### Weeks 11-12: Branch Handling & Compliance

| Task | Details |
|------|---------|
| Branch flush logic | 2-cycle flush on misprediction |
| Static branch prediction | Predict not-taken |
| RISC-V compliance | Run `riscv-tests` rv32ui suite (48 tests) |
| Fix compliance failures | Debug and fix each failing test |

**Resume after this:** *"Passing RISC-V compliance tests (rv32ui) with static branch prediction"*

#### Weeks 13-14: FPGA & Documentation

| Task | Details |
|------|---------|
| Vivado project | Create project, add constraints |
| BRAM instantiation | Convert memories to FPGA-friendly block RAM |
| UART debug | Add UART TX for register dumps |
| Synthesis | Target 100MHz, check utilization |
| README + architecture doc | Block diagrams, CPI analysis, test results |

**Resume after this:** *"Synthesized on Xilinx Artix-7 FPGA at 100MHz; integrated UART for runtime debugging"*

#### Weeks 15-20: Advanced Extensions

| Week | Extension |
|------|-----------|
| 15-16 | RV32M (multiply/divide) |
| 17-18 | CSR registers + ECALL/EBREAK/MRET |
| 19-20 | Basic L1 instruction cache |

**Resume after this:** *"Extended to RV32IM with CSR support, interrupt handling, and L1 I-cache"*

---

## Phase 12: Interview Preparation

### 12.1 Top Interview Questions from Processor Projects

**Architecture Questions:**
1. "Walk me through your processor's datapath for an ADD instruction"
2. "What is the critical path in your single-cycle processor?"
3. "Why does pipelining improve performance? What's the ideal speedup?"
4. "Explain each pipeline hazard type and how you handle them"
5. "What happens when a branch is mispredicted in your pipeline?"
6. "How does your forwarding unit work? Draw the logic"
7. "Why can't you forward from a load instruction without stalling?"
8. "What is your processor's CPI? How did you measure it?"
9. "How would you add interrupt support to your pipeline?"
10. "Explain the difference between precise and imprecise exceptions"

**RTL/Verilog Questions:**
11. "How do you prevent latch inference in `always @(*)`?"
12. "What's the difference between blocking and non-blocking assignments?"
13. "Why did you choose Verilog over SystemVerilog for RTL?"
14. "How do you handle the register file read-during-write hazard?"
15. "What's your reset strategy? Sync vs async?"
16. "How did you make your design parameterizable?"
17. "What was your most difficult debug? How did you solve it?"
18. "How would you optimize your ALU for area? For speed?"
19. "What synthesis warnings did you get and how did you fix them?"
20. "How do you ensure your RTL is lint-clean?"

**Verification Questions:**
21. "How did you verify your processor is correct?"
22. "What is a self-checking testbench?"
23. "How would you add functional coverage to your testbench?"
24. "What RISC-V compliance tests did you run?"
25. "How would you verify the forwarding unit exhaustively?"

**FPGA/Synthesis Questions:**
26. "What was your resource utilization on FPGA?"
27. "What was your maximum frequency? What limited it?"
28. "How did you handle memory on FPGA?"
29. "How would you debug a timing violation?"
30. "What's the difference between behavioral and post-synthesis simulation?"

### 12.2 How to Explain Your Processor in Interviews

**30-second elevator pitch:**
> "I designed a 5-stage pipelined RV32I processor in Verilog. It supports the full base integer instruction set with data forwarding and hazard detection. I verified it against RISC-V compliance tests and synthesized it on a Xilinx FPGA at 100MHz. The project is documented on GitHub with a self-checking verification environment."

**2-minute deep dive (when they ask "tell me more"):**
> Start with architecture → explain one interesting challenge (forwarding or branch handling) → mention testing methodology → mention FPGA results → end with what you'd improve.

**Key phrases that impress interviewers:**
- "I implemented a 3-input forwarding mux with priority logic"
- "My CPI is 1.15, accounting for load-use stalls and branch penalties"
- "I ran the rv32ui compliance suite — all 48 tests pass"
- "The critical path is through the ALU in the execute stage"
- "I use a 2-bit saturating counter for dynamic branch prediction"

### 12.3 What Differentiates Strong vs Basic Projects

```
❌ Basic College Project:
  - Single-cycle only
  - Hardcoded test programs
  - No verification methodology
  - No documentation
  - Files emailed, not on GitHub
  - "It works in simulation" (no proof)

✅ Strong Industry-Level Project:
  - Multiple architectures (single → multi → pipeline)
  - RISC-V compliance tests passing
  - Self-checking testbench with coverage
  - Lint-clean Verilog RTL with proper coding style
  - FPGA demo with UART output
  - Professional README with block diagrams
  - Git history showing incremental development
  - CPI analysis and performance comparison
  - Forwarding, hazard detection, branch prediction
```

---

## Phase 13: Common Mistakes & Industry Tips

### 13.1 Common Beginner Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Using positional port connections | Always use named ports (`.clk(clk)`) |
| 2 | No reset for sequential elements | Every flip-flop needs a reset value |
| 3 | Using `initial` in synthesizable RTL | Use `initial` only in testbenches |
| 4 | Incomplete `case`/`if-else` in `always @(*)` | Always have `default`, assign ALL outputs |
| 5 | Mixing `=` and `<=` in same block | `=` for comb, `<=` for sequential — never mix |
| 6 | Not parameterizing designs | Use `parameter` for widths, depths, etc. |
| 7 | Duplicating files across folders | Single source, use filelists/includes |
| 8 | No testbench automation | Self-checking TB with PASS/FAIL, Makefile |
| 9 | Testing only "happy path" | Test edge cases: x0 writes, branch to self, overflow |
| 10 | No waveform analysis | Always dump VCD and inspect signal timing |

### 13.2 Tips for Industry-Level Quality

1. **Lint your code:** Run `verilator --lint-only -Wall` — fix EVERY warning
2. **Clean Verilog style:** Consistent `always @(*)` for comb, `always @(posedge clk)` for seq, `localparam` for constants
3. **Write inline checks:** Even 5-10 testbench verification checks show design maturity
4. **Document decisions:** Why did you choose 2-cycle branch penalty? Why Harvard architecture?
5. **Show performance data:** CPI table, frequency achieved, resource utilization
6. **Professional Git history:** Small, meaningful commits — not one giant commit
7. **CI/CD:** GitHub Actions running your testbench on every push (free with Icarus Verilog)

### 13.3 Beginner → Intermediate → Advanced Mindset

```
🟢 BEGINNER RTL Engineer:
  "I can write Verilog that simulates correctly"
  - Focuses on: functionality
  - Thinks about: does it work?
  - Tools: simulator only
  
🟡 INTERMEDIATE RTL Engineer:
  "I can write Verilog that synthesizes correctly and meets timing"
  - Focuses on: synthesizability, timing, area
  - Thinks about: will it work on real hardware?
  - Tools: simulator + synthesizer + linter
  - Asks: "Is my code lint-clean? What's my critical path?"
  
🔴 ADVANCED RTL Engineer:
  "I can architect systems that are verifiable, maintainable, and performant"
  - Focuses on: architecture, verification, reusability
  - Thinks about: can someone else verify/modify this? What's the PPA?
  - Tools: full EDA flow + formal verification + coverage
  - Asks: "What's my functional coverage? How do I prove correctness?"
  - At this level, learns SystemVerilog for verification methodology
```

> [!IMPORTANT]
> **Your goal:** Move from 🟢 to 🟡 during this project. The pipeline processor with forwarding and FPGA demo firmly puts you at intermediate level, which is exactly what companies expect from a fresh B.Tech hire.

---

## Final Checklist — What You Should Have When Done

```
✅ Single-cycle RV32I processor (DONE — your current state)
✅ Multi-cycle RV32I processor
✅ 5-stage pipelined RV32I processor
✅ Data forwarding unit (EX-to-EX, MEM-to-EX)
✅ Hazard detection with pipeline stalling
✅ Branch handling (static prediction + flush)
✅ RISC-V rv32ui compliance tests passing
✅ Self-checking Verilog testbench with inline verification checks
✅ Lint-clean RTL (Verilator, zero warnings)
✅ FPGA synthesis (Xilinx, with timing report)
✅ UART debug interface
✅ Professional GitHub repository with:
   - Clean README with block diagrams
   - Architecture documentation
   - CPI analysis and performance data
   - Makefile for automated simulation
   - Test programs and results
✅ Resume bullet points (provided at each milestone above)
✅ Ability to explain every design decision in interviews
```

---

> [!CAUTION]
> **Start today.** Your single-cycle processor is already working — you are NOT starting from zero. Your immediate next step is **Week 1-2: Code cleanup and restructuring**. Use named ports, add the `riscv_defs.vh` header file, and set up the Makefile. This alone makes your project look 10x more professional.

---

*This 3-part roadmap covers your complete journey from current state to interview-ready RISC-V processor. Refer back to specific sections as you progress through each phase.*

| Part | Contents | Link |
|------|----------|------|
| **Part 1** | Fundamentals, ISA, Single→Multi→Pipeline Architecture, Hazards | [Part 1](file:///C:/Users/ayush/.gemini/antigravity/brain/6eb511e4-b7bd-4c46-a258-9b862f0b6238/artifacts/riscv_processor_roadmap_part1.md) |
| **Part 2** | Verilog Coding Style, Verification, FPGA, Advanced Extensions | [Part 2](file:///C:/Users/ayush/.gemini/antigravity/brain/6eb511e4-b7bd-4c46-a258-9b862f0b6238/artifacts/riscv_processor_roadmap_part2.md) |
| **Part 3** | Tools, Resources, Timeline, Interview Prep, Final Checklist | This document |
