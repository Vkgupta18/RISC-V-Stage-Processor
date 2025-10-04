`include "REG_FILE.v"
`include "ALU.v"
`include "DATA_MEM.v"

module DATAPATH(
    input [4:0] read_reg_num1,
    input [4:0] read_reg_num2,
    input [4:0] write_reg,
    input [31:0] immediate,
    input [31:0] PC_in,         // New: current PC value
    input alu_src,
    input [3:0] alu_control,
    input regwrite,
    input mem_read,             // New
    input mem_write,            // New
    input mem_to_reg,           // New
    input [2:0] funct3,         // New: for load/store sizing
    input clock,
    input reset,
    output zero_flag,
    output [31:0] alu_result_out // New: for address calculation
);

    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] write_data;
    wire [31:0] alu_input2;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;

    assign alu_input2 = alu_src ? immediate : read_data2;
    assign write_data = mem_to_reg ? mem_read_data : alu_result;
    assign alu_result_out = alu_result;

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
        read_data1,
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