`ifndef HAZARD_DETECTION_V
`define HAZARD_DETECTION_V
`timescale 1ns/1ps
/*
Hazard Detection Unit for 5-Stage Pipelined RISC-V Processor

Handles two types of hazards:
1. Load-Use Hazard: When a LOAD instruction in EX stage is immediately 
   followed by a dependent instruction in ID stage. 
   Resolution: Stall pipeline 1 cycle (freeze PC, freeze IF/ID, insert bubble in ID/EX).

2. Control Hazard (Branch/Jump): When a branch is taken or a jump occurs
   (resolved in EX stage).
   Resolution: Flush IF/ID and ID/EX pipeline registers (2-cycle penalty).

Priority: Control hazards override load-use stalls (if a branch is taken
during the same cycle as a load-use, the branch wins — no stall needed).
*/

module HAZARD_DETECTION(
    // Load-use detection: from ID/EX register
    input       id_ex_mem_read,     // Is instruction in EX a LOAD?
    input [4:0] id_ex_rd,           // Destination of LOAD in EX
    
    // Source registers of instruction in ID stage
    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,
    
    // Control hazard: branch/jump resolved in EX
    input       branch_taken,       // Branch condition met
    input       jump_taken,         // JAL or JALR
    
    // Stall/Flush outputs
    output reg  stall,              // 1 = freeze PC and IF/ID, insert NOP into ID/EX
    output reg  if_id_flush,        // 1 = flush IF/ID register
    output reg  id_ex_flush         // 1 = flush ID/EX register (insert bubble)
);

    // BUG-1 FIX: Use explicit if/else chain to make priority unambiguous
    always @(*) begin
        stall       = 1'b0;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;
        
        if (branch_taken || jump_taken) begin
            // Control Hazard — highest priority
            // Flush the two instructions that entered the pipeline after the branch/jump
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
            stall       = 1'b0;  // No stall on flush
        end
        else if (id_ex_mem_read && (id_ex_rd != 5'b0) &&
                 ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            // Load-Use Hazard — only if no control hazard
            stall       = 1'b1;
            id_ex_flush = 1'b1;  // Insert bubble into ID/EX
        end
    end

endmodule
`endif
