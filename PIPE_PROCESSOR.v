`ifndef PIPE_PROCESSOR_V
`define PIPE_PROCESSOR_V
`timescale 1ns/1ps
/*
Top-Level Module for 5-Stage Pipelined RISC-V Processor
Instantiates the pipeline datapath which contains all pipeline stages,
pipeline registers, hazard handling, and forwarding logic.

Ports:
  - clock : System clock
  - reset : Active-high asynchronous reset
*/

`include "PIPE_DATAPATH.v"

module PIPE_PROCESSOR(
    input clock,
    input reset
);

    // Debug wires (accessible from testbench via hierarchical references)
    wire [31:0] dbg_pc;
    wire [31:0] dbg_if_id_instruction;
    wire [31:0] dbg_if_id_pc;
    wire [4:0]  dbg_id_ex_rd;
    wire [4:0]  dbg_ex_mem_rd;
    wire [4:0]  dbg_mem_wb_rd;
    wire        dbg_ex_mem_regwrite;
    wire        dbg_mem_wb_regwrite;
    wire [31:0] dbg_ex_mem_alu_result;
    wire [31:0] dbg_mem_wb_write_data;
    wire        dbg_stall;
    wire        dbg_flush;

    PIPE_DATAPATH datapath(
        .clock(clock),
        .reset(reset),
        .dbg_pc(dbg_pc),
        .dbg_if_id_instruction(dbg_if_id_instruction),
        .dbg_if_id_pc(dbg_if_id_pc),
        .dbg_id_ex_rd(dbg_id_ex_rd),
        .dbg_ex_mem_rd(dbg_ex_mem_rd),
        .dbg_mem_wb_rd(dbg_mem_wb_rd),
        .dbg_ex_mem_regwrite(dbg_ex_mem_regwrite),
        .dbg_mem_wb_regwrite(dbg_mem_wb_regwrite),
        .dbg_ex_mem_alu_result(dbg_ex_mem_alu_result),
        .dbg_mem_wb_write_data(dbg_mem_wb_write_data),
        .dbg_stall(dbg_stall),
        .dbg_flush(dbg_flush)
    );

endmodule
`endif
