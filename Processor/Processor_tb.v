`include "PROCESSOR.v"

module stimulus;
    reg clock, reset;
    integer cycle_count;
    
    PROCESSOR test_processor(clock, reset);
    
    always #20 clock = ~clock;
    
    // Monitor for debugging
    always @(posedge clock) begin
        if (!reset) begin
            $display("Cycle %0d: PC=%0d, Inst=0x%h, x5=%0d, x6=%0d, x7=%0d, x8=%0d, x10=%0d", 
                     cycle_count,
                     test_processor.PC,
                     test_processor.instruction_code,
                     test_processor.datapath_module.reg_file_module.reg_memory[5],
                     test_processor.datapath_module.reg_file_module.reg_memory[6],
                     test_processor.datapath_module.reg_file_module.reg_memory[7],
                     test_processor.datapath_module.reg_file_module.reg_memory[8],
                     test_processor.datapath_module.reg_file_module.reg_memory[10]);
            cycle_count = cycle_count + 1;
        end
    end
    
    initial begin
        $dumpfile("output_wave.vcd");
        $dumpvars(0, stimulus);
        
        clock = 0;
        reset = 1;
        cycle_count = 0;
        
        $display("\n========== PROCESSOR Integration Test ==========\n");
        $display("Starting simulation...\n");
        
        #50 reset = 0;
        
        #400;  // Run for 10 cycles
        
        $display("\n========== Final Register State ==========");
        $display("x0  = %d (should be 0)", test_processor.datapath_module.reg_file_module.reg_memory[0]);
        $display("x5  = %d (expected: 10)", test_processor.datapath_module.reg_file_module.reg_memory[5]);
        $display("x6  = %d (expected: 20)", test_processor.datapath_module.reg_file_module.reg_memory[6]);
        $display("x7  = %d (expected: 30)", test_processor.datapath_module.reg_file_module.reg_memory[7]);
        $display("x8  = %d (expected: 30)", test_processor.datapath_module.reg_file_module.reg_memory[8]);
        $display("x9  = %d (expected: 0 - branch skipped)", test_processor.datapath_module.reg_file_module.reg_memory[9]);
        $display("x10 = %d (expected: 42)", test_processor.datapath_module.reg_file_module.reg_memory[10]);
        
        // Verification
        $display("\n========== Verification Results ==========");
        if (test_processor.datapath_module.reg_file_module.reg_memory[5] == 10 &&
            test_processor.datapath_module.reg_file_module.reg_memory[6] == 20 &&
            test_processor.datapath_module.reg_file_module.reg_memory[7] == 30 &&
            test_processor.datapath_module.reg_file_module.reg_memory[8] == 30 &&
            test_processor.datapath_module.reg_file_module.reg_memory[9] != 99 &&
            test_processor.datapath_module.reg_file_module.reg_memory[10] == 42) begin
            $display("✓ ALL PROCESSOR TESTS PASSED!");
            $display("  - I-type (ADDI) working");
            $display("  - R-type (ADD) working");
            $display("  - Store (SW) working");
            $display("  - Load (LW) working");
            $display("  - Branch (BEQ) working");
        end else begin
            $display("✗ PROCESSOR TESTS FAILED!");
            if (test_processor.datapath_module.reg_file_module.reg_memory[5] != 10)
                $display("  - ADDI failed: x5=%d", test_processor.datapath_module.reg_file_module.reg_memory[5]);
            if (test_processor.datapath_module.reg_file_module.reg_memory[7] != 30)
                $display("  - ADD failed: x7=%d", test_processor.datapath_module.reg_file_module.reg_memory[7]);
            if (test_processor.datapath_module.reg_file_module.reg_memory[8] != 30)
                $display("  - SW/LW failed: x8=%d", test_processor.datapath_module.reg_file_module.reg_memory[8]);
            if (test_processor.datapath_module.reg_file_module.reg_memory[9] == 99)
                $display("  - BEQ failed: x9=%d (branch didn't skip)", test_processor.datapath_module.reg_file_module.reg_memory[9]);
        end
        $display("==========================================\n");
        
        $finish;
    end
endmodule