`ifndef BRANCH_UNIT_V
`define BRANCH_UNIT_V
`timescale 1ns/1ps
/*
Branch Unit for 5-Stage Pipelined RISC-V Processor
Evaluates branch conditions and calculates branch/jump target addresses.
Operates in the EX stage on forwarded register values.

Outputs branch_taken = 1 whenever the PC should be redirected
(for both branches with true conditions AND unconditional jumps).
*/

module BRANCH_UNIT(
    input [31:0] PC,            // PC of the branch/jump instruction (from ID/EX)
    input [31:0] immediate,     // Sign-extended immediate (from ID/EX)
    input [31:0] rs1_data,      // rs1 value (forwarded) — for JALR target
    input [6:0]  opcode,        // To distinguish JAL from JALR
    input [2:0]  funct3,
    input        branch,        // Control: is branch instruction
    input        jump,          // Control: is JAL/JALR
    input        zero_flag,     // ALU zero flag
    input [31:0] alu_result,    // ALU result (for SLT-based branches)
    output reg   branch_taken,  // 1 = redirect PC to branch_target
    output [31:0] branch_target
);

    // Branch/Jump target calculation
    // JALR: target = (rs1 + imm) & ~1  (clear LSB per RISC-V spec)
    // Others (JAL, branches): target = PC + imm
    assign branch_target = (opcode == 7'b1100111) ?            // JALR opcode
                           (rs1_data + immediate) & ~32'b1 :   // JALR: rs1 + imm, clear LSB
                           (PC + immediate);                    // JAL, branches: PC + imm
    
    // Branch condition evaluation
    // BUG-2 FIX: branch_taken is the SOLE output — no double-gating in datapath needed.
    // This signal directly indicates whether the PC should be redirected.
    always @(*) begin
        branch_taken = 1'b0;
        
        if (jump) begin
            branch_taken = 1'b1;  // JAL/JALR always taken
        end else if (branch) begin
            case(funct3)
                3'b000: branch_taken = zero_flag;         // BEQ:  taken if equal
                3'b001: branch_taken = ~zero_flag;        // BNE:  taken if not equal
                3'b100: branch_taken = alu_result[0];     // BLT:  taken if less than
                3'b101: branch_taken = ~alu_result[0];    // BGE:  taken if >= 
                3'b110: branch_taken = alu_result[0];     // BLTU: taken if less than (unsigned)
                3'b111: branch_taken = ~alu_result[0];    // BGEU: taken if >= (unsigned)
                default: branch_taken = 1'b0;
            endcase
        end
    end
endmodule
`endif
