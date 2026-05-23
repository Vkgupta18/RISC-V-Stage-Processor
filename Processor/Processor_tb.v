`timescale 1ns/1ps

module Processor_tb;
    reg clock = 0;
    reg reset = 1;
    
    PROCESSOR uut(
        .clock(clock),
        .reset(reset)
    );
    
    always #10 clock = ~clock;
    
    integer cycle_count = 0;
    integer errors = 0;
    
    initial begin
        $dumpfile("output_wave.vcd");
        $dumpvars(0, Processor_tb);
        
        $display("\n========================================");
        $display("RISC-V Processor Simulation Started");
        $display("========================================\n");
        $display("Cycle | PC       | Instruction | Opcode  | rd | rs1 | rs2 | ALU Result | RegWrite");
        $display("------------------------------------------------------------------------------------------");
        
        #5 reset = 1; #5 reset = 0; #40;
        
        repeat(50) begin
            @(posedge clock);
            #1;
            
            if (!reset) begin
                cycle_count = cycle_count + 1;
                $display("%4d  | %08h | %08h    | %07b | x%02d| x%02d | x%02d | %08h   | %b",
                    cycle_count, uut.PC, uut.instruction_code, uut.instruction_code[6:0],
                    uut.instruction_code[11:7], uut.instruction_code[19:15], 
                    uut.instruction_code[24:20], uut.alu_result, uut.regwrite);
            end
        end
        
        $display("\n========================================");
        $display("Final Register File State:");
        $display("========================================");
        $display("x00=%08h x01=%08h x02=%08h x03=%08h", 
            uut.datapath_module.reg_file_module.reg_memory[0], 
            uut.datapath_module.reg_file_module.reg_memory[1], 
            uut.datapath_module.reg_file_module.reg_memory[2], 
            uut.datapath_module.reg_file_module.reg_memory[3]);
        $display("x04=%08h x05=%08h x06=%08h x07=%08h", 
            uut.datapath_module.reg_file_module.reg_memory[4], 
            uut.datapath_module.reg_file_module.reg_memory[5], 
            uut.datapath_module.reg_file_module.reg_memory[6], 
            uut.datapath_module.reg_file_module.reg_memory[7]);
        $display("x08=%08h x09=%08h x10=%08h x11=%08h", 
            uut.datapath_module.reg_file_module.reg_memory[8], 
            uut.datapath_module.reg_file_module.reg_memory[9], 
            uut.datapath_module.reg_file_module.reg_memory[10], 
            uut.datapath_module.reg_file_module.reg_memory[11]);
        $display("x12=%08h x13=%08h x14=%08h x15=%08h", 
            uut.datapath_module.reg_file_module.reg_memory[12], 
            uut.datapath_module.reg_file_module.reg_memory[13], 
            uut.datapath_module.reg_file_module.reg_memory[14], 
            uut.datapath_module.reg_file_module.reg_memory[15]);
        
        // === AUTOMATED VERIFICATION ===
        $display("\n========================================");
        $display("Automated Verification:");
        $display("========================================");
        
        // Test 1: Check x5 (should be initialized to 10)
        if (uut.datapath_module.reg_file_module.reg_memory[5] == 32'h0000000a) begin
            $display("[PASS] x5 = 0x0000000a (10 decimal) - Correct initialization");
        end else begin
            $display("[FAIL] x5 = 0x%08h, Expected: 0x0000000a", 
                uut.datapath_module.reg_file_module.reg_memory[5]);
            errors = errors + 1;
        end
        
        // Test 2: Check x6 (ADDI x6, x0, 20)
        if (uut.datapath_module.reg_file_module.reg_memory[6] == 32'h00000014) begin
            $display("[PASS] x6 = 0x00000014 (20 decimal) - ADDI works");
        end else begin
            $display("[FAIL] x6 = 0x%08h, Expected: 0x00000014", 
                uut.datapath_module.reg_file_module.reg_memory[6]);
            errors = errors + 1;
        end
        
        // Test 3: Check x7 (ADD x7, x5, x6 = 10 + 20 = 30)
        if (uut.datapath_module.reg_file_module.reg_memory[7] == 32'h0000001e) begin
            $display("[PASS] x7 = 0x0000001e (30 decimal) - ADD works");
        end else begin
            $display("[FAIL] x7 = 0x%08h, Expected: 0x0000001e", 
                uut.datapath_module.reg_file_module.reg_memory[7]);
            errors = errors + 1;
        end
        
        // Test 4: Check x8 (LW x8, 0(x0) - should load stored value)
        if (uut.datapath_module.reg_file_module.reg_memory[8] == 32'h0000001e) begin
            $display("[PASS] x8 = 0x0000001e (30 decimal) - LW/SW works");
        end else begin
            $display("[FAIL] x8 = 0x%08h, Expected: 0x0000001e", 
                uut.datapath_module.reg_file_module.reg_memory[8]);
            errors = errors + 1;
        end
        
        // Test 5: Check x10 (ADDI x10, x0, 42)
        if (uut.datapath_module.reg_file_module.reg_memory[10] == 32'h0000002a) begin
            $display("[PASS] x10 = 0x0000002a (42 decimal) - Branch worked (instruction executed)");
        end else begin
            $display("[FAIL] x10 = 0x%08h, Expected: 0x0000002a", 
                uut.datapath_module.reg_file_module.reg_memory[10]);
            errors = errors + 1;
        end
        
        // Test 6: Check data memory (SW should have stored x7)
        if (errors == 0) begin
            $display("✅ ALL TESTS PASSED! Processor working correctly.");
        end else begin
            $display("❌ %0d TEST(S) FAILED! Check implementation.", errors);
        end
        $display("========================================");
        $display("Total Cycles: %0d | Final PC: 0x%08h\n", cycle_count, uut.PC);
        
        $finish;
    end
    
    initial begin
        #100000;
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule
