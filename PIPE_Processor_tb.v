`timescale 1ns/1ps
`include "PIPE_PROCESSOR.v"
/*
Testbench for 5-Stage Pipelined RISC-V Processor
Comprehensive automated verification covering:
  1.  Basic ALU (ADDI, ADD, SUB, SLT, ANDI, ORI, XORI)
  2.  Data hazards — back-to-back RAW (forwarding)
  3.  Load-use hazard (stall + forwarding)
  4.  Store-after-load
  5.  Branch taken & not-taken (BEQ, BNE)
  6.  Backward branch (loop with BNE, negative offset)
  7.  JAL (with link register + flush)
  8.  JALR (with link register + flush)
  9.  LUI, AUIPC
  10. Shift instructions (SLLI, SRL, SRAI with signed values)
  
Prints per-cycle pipeline state and final register dump.
*/

module PIPE_Processor_tb;
    reg clock = 0;
    reg reset = 1;
    
    PIPE_PROCESSOR uut(
        .clock(clock),
        .reset(reset)
    );
    
    always #10 clock = ~clock;  // 50 MHz clock (20ns period)
    
    integer cycle_count = 0;
    integer errors = 0;
    integer pass_count = 0;
    
    initial begin
        $dumpfile("pipe_output_wave.vcd");
        $dumpvars(0, PIPE_Processor_tb);
        
        $display("\n==========================================================================");
        $display("  5-Stage Pipelined RISC-V Processor — Simulation Started");
        $display("==========================================================================\n");
        $display("Cycle |   PC   | IF/ID Instr | Stall | Flush | EX/MEM rd | MEM/WB rd | WB Data");
        $display("------|--------|------------|-------|-------|-----------|-----------|----------");
        
        // Reset sequence
        #5  reset = 1;
        #15 reset = 0;
        
        // Run for enough cycles to complete entire test program
        // Program has ~33 instructions + stalls + flushes + backward branches ≈ 70 cycles
        repeat(80) begin
            @(posedge clock);
            #1;  // Small delay for signal settling
            
            if (!reset) begin
                cycle_count = cycle_count + 1;
                $display("%4d  | %04h   | %08h   |   %b   |   %b   |    x%02d    |    x%02d    | %08h",
                    cycle_count,
                    uut.dbg_pc,
                    uut.dbg_if_id_instruction,
                    uut.dbg_stall,
                    uut.dbg_flush,
                    uut.dbg_ex_mem_rd,
                    uut.dbg_mem_wb_rd,
                    uut.dbg_mem_wb_write_data
                );
            end
        end
        
        // ================================================================
        //  Register File Dump
        // ================================================================
        $display("\n==========================================================================");
        $display("  Final Register File State");
        $display("==========================================================================");
        $display("  x00(zero)=%08h  x01=%08h  x02=%08h  x03=%08h", 
            uut.datapath.reg_file.reg_memory[0], 
            uut.datapath.reg_file.reg_memory[1], 
            uut.datapath.reg_file.reg_memory[2], 
            uut.datapath.reg_file.reg_memory[3]);
        $display("  x04=%08h  x05=%08h  x06=%08h  x07=%08h", 
            uut.datapath.reg_file.reg_memory[4], 
            uut.datapath.reg_file.reg_memory[5], 
            uut.datapath.reg_file.reg_memory[6], 
            uut.datapath.reg_file.reg_memory[7]);
        $display("  x08=%08h  x09=%08h  x10=%08h  x11=%08h", 
            uut.datapath.reg_file.reg_memory[8], 
            uut.datapath.reg_file.reg_memory[9], 
            uut.datapath.reg_file.reg_memory[10], 
            uut.datapath.reg_file.reg_memory[11]);
        $display("  x12=%08h  x13=%08h  x14=%08h  x15=%08h", 
            uut.datapath.reg_file.reg_memory[12], 
            uut.datapath.reg_file.reg_memory[13], 
            uut.datapath.reg_file.reg_memory[14], 
            uut.datapath.reg_file.reg_memory[15]);
        $display("  x16=%08h  x17=%08h  x18=%08h  x19=%08h", 
            uut.datapath.reg_file.reg_memory[16], 
            uut.datapath.reg_file.reg_memory[17],
            uut.datapath.reg_file.reg_memory[18],
            uut.datapath.reg_file.reg_memory[19]);
        $display("  x20=%08h  x21=%08h  x22=%08h  x23=%08h", 
            uut.datapath.reg_file.reg_memory[20], 
            uut.datapath.reg_file.reg_memory[21],
            uut.datapath.reg_file.reg_memory[22],
            uut.datapath.reg_file.reg_memory[23]);
        $display("  x24=%08h  x25=%08h  x26=%08h", 
            uut.datapath.reg_file.reg_memory[24], 
            uut.datapath.reg_file.reg_memory[25],
            uut.datapath.reg_file.reg_memory[26]);
        
        // ================================================================
        //  Automated Verification
        // ================================================================
        $display("\n==========================================================================");
        $display("  Automated Verification");
        $display("==========================================================================");
        
        // Test 1: ADDI x1, x0, 10 → x1 = 10
        if (uut.datapath.reg_file.reg_memory[1] == 32'h0000000A) begin
            $display("  [PASS] x1  = 0x%08h (expected 0x0000000A) — ADDI basic", uut.datapath.reg_file.reg_memory[1]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x1  = 0x%08h (expected 0x0000000A) — ADDI basic", uut.datapath.reg_file.reg_memory[1]);
            errors = errors + 1;
        end
        
        // Test 2: ADDI x2, x0, 20 → x2 = 20
        if (uut.datapath.reg_file.reg_memory[2] == 32'h00000014) begin
            $display("  [PASS] x2  = 0x%08h (expected 0x00000014) — ADDI basic", uut.datapath.reg_file.reg_memory[2]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x2  = 0x%08h (expected 0x00000014) — ADDI basic", uut.datapath.reg_file.reg_memory[2]);
            errors = errors + 1;
        end
        
        // Test 3: ADD x3, x1, x2 → x3 = 30 — RAW forwarding test
        if (uut.datapath.reg_file.reg_memory[3] == 32'h0000001E) begin
            $display("  [PASS] x3  = 0x%08h (expected 0x0000001E) — ADD + RAW forwarding", uut.datapath.reg_file.reg_memory[3]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x3  = 0x%08h (expected 0x0000001E) — ADD + RAW forwarding", uut.datapath.reg_file.reg_memory[3]);
            errors = errors + 1;
        end
        
        // Test 4: ADDI x4, x3, 5 → x4 = 35 — forwarding from previous
        if (uut.datapath.reg_file.reg_memory[4] == 32'h00000023) begin
            $display("  [PASS] x4  = 0x%08h (expected 0x00000023) — ADDI + forwarding", uut.datapath.reg_file.reg_memory[4]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x4  = 0x%08h (expected 0x00000023) — ADDI + forwarding", uut.datapath.reg_file.reg_memory[4]);
            errors = errors + 1;
        end
        
        // Test 5: LW x5, 0(x0) → x5 = 35 — load from stored value
        if (uut.datapath.reg_file.reg_memory[5] == 32'h00000023) begin
            $display("  [PASS] x5  = 0x%08h (expected 0x00000023) — LW/SW memory", uut.datapath.reg_file.reg_memory[5]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x5  = 0x%08h (expected 0x00000023) — LW/SW memory", uut.datapath.reg_file.reg_memory[5]);
            errors = errors + 1;
        end
        
        // Test 6: ADD x6, x5, x1 → x6 = 45 — load-use hazard test
        if (uut.datapath.reg_file.reg_memory[6] == 32'h0000002D) begin
            $display("  [PASS] x6  = 0x%08h (expected 0x0000002D) — Load-use hazard resolved", uut.datapath.reg_file.reg_memory[6]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x6  = 0x%08h (expected 0x0000002D) — Load-use hazard", uut.datapath.reg_file.reg_memory[6]);
            errors = errors + 1;
        end
        
        // Test 7: ADDI x7, x0, 77 → x7 = 77 — after BNE not-taken
        if (uut.datapath.reg_file.reg_memory[7] == 32'h0000004D) begin
            $display("  [PASS] x7  = 0x%08h (expected 0x0000004D) — Branch NOT taken OK", uut.datapath.reg_file.reg_memory[7]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x7  = 0x%08h (expected 0x0000004D) — Branch NOT taken", uut.datapath.reg_file.reg_memory[7]);
            errors = errors + 1;
        end
        
        // Test 8: x8 should NOT be 99 — BEQ taken should skip ADDI x8
        if (uut.datapath.reg_file.reg_memory[8] != 32'h00000063) begin
            $display("  [PASS] x8  = 0x%08h (NOT 0x63=99) — Branch TAKEN flush OK", uut.datapath.reg_file.reg_memory[8]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x8  = 0x%08h (should NOT be 0x63=99) — Branch flush failed", uut.datapath.reg_file.reg_memory[8]);
            errors = errors + 1;
        end
        
        // Test 9: ADDI x9, x0, 42 → x9 = 42 — branch target
        if (uut.datapath.reg_file.reg_memory[9] == 32'h0000002A) begin
            $display("  [PASS] x9  = 0x%08h (expected 0x0000002A) — Branch target reached", uut.datapath.reg_file.reg_memory[9]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x9  = 0x%08h (expected 0x0000002A) — Branch target", uut.datapath.reg_file.reg_memory[9]);
            errors = errors + 1;
        end
        
        // Test 10: LUI x10, 0xDEADB → x10 = 0xDEADB000
        if (uut.datapath.reg_file.reg_memory[10] == 32'hDEADB000) begin
            $display("  [PASS] x10 = 0x%08h (expected 0xDEADB000) — LUI", uut.datapath.reg_file.reg_memory[10]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x10 = 0x%08h (expected 0xDEADB000) — LUI", uut.datapath.reg_file.reg_memory[10]);
            errors = errors + 1;
        end
        
        // Test 11: AUIPC x11, 0x1 at PC=0x34 → x11 = 0x1034
        if (uut.datapath.reg_file.reg_memory[11] == 32'h00001034) begin
            $display("  [PASS] x11 = 0x%08h (expected 0x00001034) — AUIPC", uut.datapath.reg_file.reg_memory[11]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x11 = 0x%08h (expected 0x00001034) — AUIPC", uut.datapath.reg_file.reg_memory[11]);
            errors = errors + 1;
        end
        
        // Test 12: JAL x12, 8 at PC=0x38 → x12 = 0x3C (PC+4)
        if (uut.datapath.reg_file.reg_memory[12] == 32'h0000003C) begin
            $display("  [PASS] x12 = 0x%08h (expected 0x0000003C) — JAL link", uut.datapath.reg_file.reg_memory[12]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x12 = 0x%08h (expected 0x0000003C) — JAL link", uut.datapath.reg_file.reg_memory[12]);
            errors = errors + 1;
        end
        
        // Test 13: x13 should NOT be 88 — JAL should have skipped ADDI x13
        if (uut.datapath.reg_file.reg_memory[13] != 32'h00000058) begin
            $display("  [PASS] x13 = 0x%08h (NOT 0x58=88) — JAL flush OK", uut.datapath.reg_file.reg_memory[13]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x13 = 0x%08h (should NOT be 0x58=88) — JAL flush failed", uut.datapath.reg_file.reg_memory[13]);
            errors = errors + 1;
        end
        
        // Test 14: SUB x14, x6, x1 → x14 = 45 - 10 = 35
        if (uut.datapath.reg_file.reg_memory[14] == 32'h00000023) begin
            $display("  [PASS] x14 = 0x%08h (expected 0x00000023) — SUB", uut.datapath.reg_file.reg_memory[14]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x14 = 0x%08h (expected 0x00000023) — SUB", uut.datapath.reg_file.reg_memory[14]);
            errors = errors + 1;
        end
        
        // Test 15: SLT x15, x1, x2 → x15 = (10 < 20) = 1
        if (uut.datapath.reg_file.reg_memory[15] == 32'h00000001) begin
            $display("  [PASS] x15 = 0x%08h (expected 0x00000001) — SLT", uut.datapath.reg_file.reg_memory[15]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x15 = 0x%08h (expected 0x00000001) — SLT", uut.datapath.reg_file.reg_memory[15]);
            errors = errors + 1;
        end
        
        // Test 16: ANDI x16, x7, 0xFF → x16 = 77 & 255 = 77
        if (uut.datapath.reg_file.reg_memory[16] == 32'h0000004D) begin
            $display("  [PASS] x16 = 0x%08h (expected 0x0000004D) — ANDI", uut.datapath.reg_file.reg_memory[16]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x16 = 0x%08h (expected 0x0000004D) — ANDI", uut.datapath.reg_file.reg_memory[16]);
            errors = errors + 1;
        end
        
        // Test 17: ORI x17, x0, 0x0F → x17 = 15
        if (uut.datapath.reg_file.reg_memory[17] == 32'h0000000F) begin
            $display("  [PASS] x17 = 0x%08h (expected 0x0000000F) — ORI", uut.datapath.reg_file.reg_memory[17]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x17 = 0x%08h (expected 0x0000000F) — ORI", uut.datapath.reg_file.reg_memory[17]);
            errors = errors + 1;
        end
        
        // Test 18: SLLI x18, x1, 3 → x18 = 10 << 3 = 80
        if (uut.datapath.reg_file.reg_memory[18] == 32'h00000050) begin
            $display("  [PASS] x18 = 0x%08h (expected 0x00000050) — SLLI (shift left)", uut.datapath.reg_file.reg_memory[18]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x18 = 0x%08h (expected 0x00000050) — SLLI (shift left)", uut.datapath.reg_file.reg_memory[18]);
            errors = errors + 1;
        end
        
        // Test 19: SRL x20, x18, x19 → x20 = 80 >> 2 = 20
        if (uut.datapath.reg_file.reg_memory[20] == 32'h00000014) begin
            $display("  [PASS] x20 = 0x%08h (expected 0x00000014) — SRL (shift right logical)", uut.datapath.reg_file.reg_memory[20]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x20 = 0x%08h (expected 0x00000014) — SRL (shift right logical)", uut.datapath.reg_file.reg_memory[20]);
            errors = errors + 1;
        end
        
        // Test 20: SRAI x22, x21, 4 → x22 = 0xFFFFEFFF >>> 4 = 0xFFFFFEFF (arithmetic right shift, sign extended)
        if (uut.datapath.reg_file.reg_memory[22] == 32'hFFFFFEFF) begin
            $display("  [PASS] x22 = 0x%08h (expected 0xFFFFFEFF) — SRAI (arithmetic right shift, signed)", uut.datapath.reg_file.reg_memory[22]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x22 = 0x%08h (expected 0xFFFFFEFF) — SRAI (arithmetic right shift, signed)", uut.datapath.reg_file.reg_memory[22]);
            errors = errors + 1;
        end
        
        // Test 21: JALR x24, x23, 0 at PC=0x6C → x24 = 0x70 (PC+4)
        if (uut.datapath.reg_file.reg_memory[24] == 32'h00000070) begin
            $display("  [PASS] x24 = 0x%08h (expected 0x00000070) — JALR link register", uut.datapath.reg_file.reg_memory[24]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x24 = 0x%08h (expected 0x00000070) — JALR link register", uut.datapath.reg_file.reg_memory[24]);
            errors = errors + 1;
        end
        
        // Test 22: x25 should be 0 after backward branch loop (3→2→1→0)
        if (uut.datapath.reg_file.reg_memory[25] == 32'h00000000) begin
            $display("  [PASS] x25 = 0x%08h (expected 0x00000000) — Backward branch loop completed", uut.datapath.reg_file.reg_memory[25]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x25 = 0x%08h (expected 0x00000000) — Backward branch loop", uut.datapath.reg_file.reg_memory[25]);
            errors = errors + 1;
        end
        
        // Test 23: XORI x26, x7, 0xFF → x26 = 77 ^ 255 = 178 (0xB2)
        if (uut.datapath.reg_file.reg_memory[26] == 32'h000000B2) begin
            $display("  [PASS] x26 = 0x%08h (expected 0x000000B2) — XORI", uut.datapath.reg_file.reg_memory[26]);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] x26 = 0x%08h (expected 0x000000B2) — XORI", uut.datapath.reg_file.reg_memory[26]);
            errors = errors + 1;
        end
        
        // ================================================================
        //  Summary
        // ================================================================
        $display("\n==========================================================================");
        if (errors == 0) begin
            $display("  ✅ ALL %0d TESTS PASSED! Pipeline processor working correctly.", pass_count);
        end else begin
            $display("  ❌ %0d PASSED, %0d FAILED. Check implementation.", pass_count, errors);
        end
        $display("  Total Cycles: %0d | Final PC: 0x%08h", cycle_count, uut.dbg_pc);
        $display("==========================================================================\n");
        
        $finish;
    end
    
    // Timeout safety
    initial begin
        #300000;
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule
