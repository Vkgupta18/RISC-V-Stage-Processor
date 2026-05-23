	`timescale 1ns/1ps
/*
Data Memory module for Load/Store instructions
Byte-addressable memory with 256 bytes
Supports LW, LH, LB (and their unsigned variants), SW, SH, SB
*/

module DATA_MEM(
    input clock,
    input reset,
    input mem_read,
    input mem_write,
    input [2:0] funct3,        // Determines load/store size
    input [31:0] address,
    input [31:0] write_data,
    output reg [31:0] read_data
);
    reg [7:0] memory [0:255];  // 256 bytes of memory
    wire [7:0] addr = address[7:0];  // Mask to 8 bits (wrap within 256 bytes)
    
    // Initialize memory (optional)
    integer i;
    always @(posedge reset) begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 8'b0;
    end
    
    // Memory Read Logic
    always @(*) begin
        read_data = 32'b0;  // Default value (prevents latch)
        if (mem_read) begin
            case(funct3)
                3'b000: // LB (Load Byte - sign extended)
                    read_data = {{24{memory[addr][7]}}, memory[addr]};
                3'b001: // LH (Load Half - sign extended)
                    read_data = {{16{memory[addr+1][7]}}, memory[addr+1], memory[addr]};
                3'b010: // LW (Load Word)
                    read_data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
                3'b100: // LBU (Load Byte Unsigned)
                    read_data = {24'b0, memory[addr]};
                3'b101: // LHU (Load Half Unsigned)
                    read_data = {16'b0, memory[addr+1], memory[addr]};
                default:
                    read_data = 32'b0;
            endcase
        end
    end
    
    // Memory Write Logic
    always @(posedge clock) begin
        if (mem_write) begin
            case(funct3)
                3'b000: // SB (Store Byte)
                    memory[addr] <= write_data[7:0];
                3'b001: // SH (Store Half)
                    {memory[addr+1], memory[addr]} <= write_data[15:0];
                3'b010: // SW (Store Word)
                    {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]} <= write_data;
                default: begin end
            endcase
        end
    end
endmodule
