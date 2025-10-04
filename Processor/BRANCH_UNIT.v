/*
Branch Unit evaluates branch conditions and calculates target addresses
*/

module BRANCH_UNIT(
    input [31:0] PC,
    input [31:0] immediate,
    input [31:0] rs1_data,      // For JALR
    input [2:0] funct3,
    input branch,
    input jump,
    input zero_flag,
    input [31:0] alu_result,    // For signed comparison
    output reg branch_taken,
    output [31:0] branch_target
);

    // Branch target calculation
    assign branch_target = (funct3 == 3'b000 && jump) ? // JALR
                          (rs1_data + immediate) & ~32'b1 :  // Clear LSB
                          (PC + immediate);                   // JAL, branches
    
    // Branch condition evaluation
    always @(*) begin
        branch_taken = 1'b0;
        
        if (jump) begin
            branch_taken = 1'b1;  // JAL/JALR always taken
        end else if (branch) begin
            case(funct3)
                3'b000: branch_taken = zero_flag;        // BEQ
                3'b001: branch_taken = ~zero_flag;       // BNE
                3'b100: branch_taken = alu_result[0];    // BLT
                3'b101: branch_taken = ~alu_result[0];   // BGE
                3'b110: branch_taken = alu_result[0];    // BLTU
                3'b111: branch_taken = ~alu_result[0];   // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
    end
endmodule