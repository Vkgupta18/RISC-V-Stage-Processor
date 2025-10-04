`include "IFU.v"
`include "CONTROL.v"
`include "DATAPATH.v"
`include "IMM_GEN.v"
`include "BRANCH_UNIT.v"

module PROCESSOR(
    input clock,
    input reset
);

    // Instruction fetch wires
    wire [31:0] instruction_code;
    wire [31:0] PC;
    wire branch_taken;
    wire [31:0] branch_target;
    
    // Control signals
    wire [3:0] alu_control;
    wire regwrite, alu_src, mem_read, mem_write, mem_to_reg, branch, jump;
    
    // Immediate value
    wire [31:0] immediate;
    
    // Datapath signals
    wire zero_flag;
    wire [31:0] alu_result;
    wire [31:0] rs1_data;  // For JALR

    // Instruction Fetch Unit
    IFU ifu_module(
        clock,
        reset,
        branch_taken,
        jump,
        branch_target,
        instruction_code,
        PC
    );

    // Immediate Generator
    IMM_GEN imm_gen_module(
        instruction_code,
        immediate
    );

    // Control Unit
    CONTROL control_module(
        instruction_code[6:0],   // opcode
        instruction_code[14:12], // funct3
        instruction_code[31:25], // funct7
        alu_control,
        regwrite,
        alu_src,
        mem_read,
        mem_write,
        mem_to_reg,
        branch,
        jump
    );

    // Datapath
    DATAPATH datapath_module(
        instruction_code[19:15], // rs1
        instruction_code[24:20], // rs2
        instruction_code[11:7],  // rd
        immediate,
        PC,
        alu_src,
        alu_control,
        regwrite,
        mem_read,
        mem_write,
        mem_to_reg,
        instruction_code[14:12], // funct3
        clock,
        reset,
        zero_flag,
        alu_result
    );
    
    // Branch Unit
    BRANCH_UNIT branch_unit(
        PC,
        immediate,
        rs1_data,
        instruction_code[14:12], // funct3
        branch,
        jump,
        zero_flag,
        alu_result,
        branch_taken,
        branch_target
    );

endmodule