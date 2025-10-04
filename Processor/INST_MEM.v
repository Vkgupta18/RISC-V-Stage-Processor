/* 
Instruction memory takes in two inputs: A 32-bit Program counter and a 1-bit reset. 
The memory is initialized when reset is 1.
When reset is set to 0, Based on the value of PC, corresponding 32-bit Instruction code is output
*/
module INST_MEM(
    input [31:0] PC,
    input reset,
    output [31:0] Instruction_Code
);
    reg [7:0] Memory [0:127];

    assign Instruction_Code = {Memory[PC+3], Memory[PC+2], Memory[PC+1], Memory[PC]};

    always @(posedge reset) begin
        // ADDI x5, x0, 10  (x5 = 10)
        {Memory[3], Memory[2], Memory[1], Memory[0]} = 32'b00000000101000000000001010010011;
        
        // ADDI x6, x0, 20  (x6 = 20)
        {Memory[7], Memory[6], Memory[5], Memory[4]} = 32'b00000001010000000000001100010011;
        
        // ADD x7, x5, x6  (x7 = 30)
        {Memory[11], Memory[10], Memory[9], Memory[8]} = 32'b00000000011000101000001110110011;
        
        // SW x7, 0(x0)  (Store x7 to memory address 0)
        {Memory[15], Memory[14], Memory[13], Memory[12]} = 32'b00000000011100000010000000100011;
        
        // LW x8, 0(x0)  (Load from memory to x8)
        {Memory[19], Memory[18], Memory[17], Memory[16]} = 32'b00000000000000000010010000000011;
        
        // BEQ x5, x5, 8  (Should branch - skip next instruction)
        {Memory[23], Memory[22], Memory[21], Memory[20]} = 32'b00000000010100101000010001100011;
        
        // ADDI x9, x0, 99  (This should be skipped)
        {Memory[27], Memory[26], Memory[25], Memory[24]} = 32'b00000110001100000000010010010011;
        
        // ADDI x10, x0, 42  (x10 = 42)
        {Memory[31], Memory[30], Memory[29], Memory[28]} = 32'b00000010101000000000010100010011;
    end
endmodule