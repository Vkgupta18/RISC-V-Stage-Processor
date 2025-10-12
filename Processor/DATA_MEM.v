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
    
    // Initialize memory (optional)
    integer i;
    always @(posedge reset) begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 8'b0;
    end
    
    // Memory Read Logic (combinational)
    always @(*) begin
        read_data = 32'b0; // default
        if (mem_read) begin
            case(funct3)
                3'b000: // LB (Load Byte - sign extended)
                    read_data = {{24{memory[address][7]}}, memory[address]};
                3'b001: // LH (Load Half - sign extended)
                    read_data = {{16{memory[address+1][7]}}, memory[address+1], memory[address]};
                3'b010: // LW (Load Word)
                    read_data = {memory[address+3], memory[address+2], memory[address+1], memory[address]};
                3'b100: // LBU (Load Byte Unsigned)
                    read_data = {24'b0, memory[address]};
                3'b101: // LHU (Load Half Unsigned)
                    read_data = {16'b0, memory[address+1], memory[address]};
                default:
                    read_data = 32'b0;
            endcase
        end
    end
    
    // Memory Write Logic (sequential)
    always @(posedge clock) begin
        if (mem_write) begin
            case(funct3)
                3'b000: // SB (Store Byte)
                    memory[address] <= write_data[7:0];
                3'b001: // SH (Store Half)
                    {memory[address+1], memory[address]} <= write_data[15:0];
                3'b010: // SW (Store Word)
                    {memory[address+3], memory[address+2], memory[address+1], memory[address]} <= write_data;
                default: begin end
            endcase
        end
    end
endmodule