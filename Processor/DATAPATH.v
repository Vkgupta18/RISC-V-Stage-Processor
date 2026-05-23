	`timescale 1ns/1ps
`include "REG_FILE.v"
`include "ALU.v"
`include "DATA_MEM.v"

module DATAPATH(
    input [4:0] read_reg_num1,
    input [4:0] read_reg_num2,
    input [4:0] write_reg,
    input [31:0] immediate,
    input [31:0] PC_in,         // Current PC value
    input alu_src,
    input alu_pc_src,           // 1=use PC as ALU input1 (for AUIPC)
    input [3:0] alu_control,
    input regwrite,
    input mem_read,
    input mem_write,
    input mem_to_reg,
    input jump,                 // For JAL/JALR write-back (PC+4)
    input [2:0] funct3,         // For load/store sizing
    input clock,
    input reset,
    output zero_flag,
    output [31:0] alu_result_out,
    output [31:0] rs1_data_out   // rs1 value for JALR target in branch unit
);

    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] write_data;
    wire [31:0] alu_input1;
    wire [31:0] alu_input2;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;

    // MUX 1: ALU input1 — PC (for AUIPC) or rs1 (everything else)
    assign alu_input1 = alu_pc_src ? PC_in : read_data1;

    // MUX 2: ALU input2 — immediate or rs2
    assign alu_input2 = alu_src ? immediate : read_data2;

    // MUX 3: Write-back — PC+4 (for JAL/JALR), memory data (loads), or ALU result
    assign write_data = jump ? (PC_in + 32'd4) :
                        (mem_to_reg ? mem_read_data : alu_result);

    assign alu_result_out = alu_result;
    assign rs1_data_out = read_data1;  // Expose rs1 for JALR target calculation

    REG_FILE reg_file_module(
        read_reg_num1,
        read_reg_num2,
        write_reg,
        write_data,
        read_data1,
        read_data2,
        regwrite,
        clock,
        reset
    );

    ALU alu_module(
        alu_input1,          // Was read_data1, now goes through MUX
        alu_input2,
        alu_control,
        alu_result,
        zero_flag
    );
    
    DATA_MEM data_memory(
        clock,
        reset,
        mem_read,
        mem_write,
        funct3,
        alu_result,      // Address from ALU
        read_data2,      // Data to store
        mem_read_data    // Data loaded from memory
    );
     
endmodule
