`ifndef DATA_MEM_V
`define DATA_MEM_V
`timescale 1ns/1ps
/*
Data Memory for 5-Stage Pipelined RISC-V Processor
Byte-addressable, 256 bytes.
Supports LW, LH, LB (signed), LHU, LBU (unsigned), SW, SH, SB.

NOTE: Address is truncated to 8 bits (256 bytes). Out-of-range
accesses will silently wrap — no alignment or range exceptions.
*/

module DATA_MEM(
    input clock,
    input reset,
    input mem_read,
    input mem_write,
    input [2:0] funct3,
    input [31:0] address,
    input [31:0] write_data,
    output reg [31:0] read_data
);
    reg [7:0] memory [0:255];
    wire [7:0] addr = address[7:0];
    
    // Initialize memory on reset (synthesizable pattern)
    integer i;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 256; i = i + 1)
                memory[i] <= 8'b0;
        end
        else if (mem_write) begin
            case(funct3)
                3'b000: // SB
                    memory[addr] <= write_data[7:0];
                3'b001: // SH
                    {memory[addr+1], memory[addr]} <= write_data[15:0];
                3'b010: // SW
                    {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]} <= write_data;
                default: begin end
            endcase
        end
    end
    
    // Memory Read — combinational
    always @(*) begin
        read_data = 32'b0;
        if (mem_read) begin
            case(funct3)
                3'b000: // LB (sign-extended)
                    read_data = {{24{memory[addr][7]}}, memory[addr]};
                3'b001: // LH (sign-extended)
                    read_data = {{16{memory[addr+1][7]}}, memory[addr+1], memory[addr]};
                3'b010: // LW
                    read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
                3'b100: // LBU (zero-extended)
                    read_data = {24'b0, memory[addr]};
                3'b101: // LHU (zero-extended)
                    read_data = {16'b0, memory[addr+1], memory[addr]};
                default:
                    read_data = 32'b0;
            endcase
        end
    end
endmodule
`endif
