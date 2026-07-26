`ifndef REG_FILE_V
`define REG_FILE_V
`timescale 1ns/1ps
/*
Register File for 5-Stage Pipelined RISC-V Processor
32 registers, each 32-bit wide. x0 is hardwired to zero.

KEY FEATURE for pipeline: Write-first (internal forwarding).
When reading and writing the same register on the same clock edge,
the NEW (written) value is forwarded to the read port.
This resolves WB->ID same-cycle data hazards without extra stalls.
*/

module REG_FILE(
    input [4:0] read_reg_num1,
    input [4:0] read_reg_num2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2,
    input regwrite,
    input clock,
    input reset
);

    reg [31:0] reg_memory [31:0];

    // Initialize registers on reset (synthesizable pattern: posedge clock or posedge reset)
    integer k;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (k = 0; k < 32; k = k + 1)
                reg_memory[k] <= k;  // Init each register to its index for debug
        end
        else if (regwrite && (write_reg != 5'b0)) begin
            reg_memory[write_reg] <= write_data;
        end
    end

    // Write-first forwarding: if reading same reg being written, return write_data
    // Register 0 (x0) is always zero per RISC-V spec
    assign read_data1 = (read_reg_num1 == 5'b0) ? 32'd0 :
                         (regwrite && (write_reg == read_reg_num1) && (write_reg != 5'b0)) ? write_data :
                         reg_memory[read_reg_num1];

    assign read_data2 = (read_reg_num2 == 5'b0) ? 32'd0 :
                         (regwrite && (write_reg == read_reg_num2) && (write_reg != 5'b0)) ? write_data :
                         reg_memory[read_reg_num2];

endmodule
`endif
