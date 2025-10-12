/*
ALU module, which takes two operands of size 32-bits each and a 4-bit ALU_control as input.
Operation is performed on the basis of ALU_control value and output is 32-bit ALU_result. 
If the ALU_result is zero, a ZERO FLAG is set.
*/

/*
ALU Control lines | Function
-----------------------------
        0000    Bitwise-AND
        0001    Bitwise-OR
        0010	Add (A+B)
        0100	Subtract (A-B)
        1000	Set on less than
        0011    Shift left logical
        0101    Shift right logical
        0110    Multiply
        0111    Bitwise-XOR
*/

module ALU (
    input [31:0] in1,in2, 
    input[3:0] alu_control,
    output reg [31:0] alu_result,
    output reg zero_flag
);
    always @(*) begin
        // Default outputs to avoid latches
        alu_result = 32'd0;
        zero_flag = 1'b0;
        // Operating based on control input
        case(alu_control)

        4'b0000: alu_result = in1&in2;
        4'b0001: alu_result = in1|in2;
        4'b0010: alu_result = in1+in2;
        4'b0011: alu_result = in1 << in2[4:0];     // SLL (shift left logical)
        4'b0100: alu_result = in1-in2;
        4'b0101: alu_result = in1 >> in2[4:0];     // SRL (shift right logical)
        4'b0110: alu_result = in1 * in2;           // MUL
        4'b0111: alu_result = in1 ^ in2;           // XOR
        4'b1000: alu_result = ($signed(in1) < $signed(in2)) ? 32'd1 : 32'd0;  // SLT (signed)
        4'b1001: alu_result = (in1 < in2) ? 32'd1 : 32'd0;                    // SLTU (unsigned)
        4'b1010: alu_result = $signed(in1) >>> in2[4:0];                      // SRA (shift right arithmetic)          
        4'b1011: alu_result = in2;                                          // Pass B (for LUI)
        4'b1100: alu_result = in1 + in2;                                      // PC + imm (for AUIPC)
        default: alu_result = 32'd0;
        endcase

        // Setting Zero_flag if ALU_result is zero
        if (alu_result == 0)
            zero_flag = 1'b1;
        else
            zero_flag = 1'b0;
        
    end
endmodule