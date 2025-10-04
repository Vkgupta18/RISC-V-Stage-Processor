/*
The instruction fetch unit has clock and reset pins as input and 32-bit instruction code as output.
Internally the block has Instruction Memory, Program Counter(P.C) and an adder to increment counter by 4, 
on every positive clock edge.
*/
`include "INST_MEM.v"

module IFU(
    input clock,
    input reset,
    input branch_taken,        // New: branch condition result
    input jump,                // New: is jump instruction
    input [31:0] branch_target, // New: calculated branch/jump target
    output [31:0] Instruction_Code,
    output [31:0] PC_out       // New: output current PC
);
    reg [31:0] PC = 32'b0;
    
    assign PC_out = PC;

    // Initializing the instruction memory block
    INST_MEM instr_mem(PC, reset, Instruction_Code);

    always @(posedge clock) begin
        if(reset == 1)  //If reset is one, clear the program counter
            PC <= 0;
        else if(jump || branch_taken)
            PC <= branch_target;
        else
            PC <= PC + 4;   // Increment program counter on positive clock edge
    end
endmodule