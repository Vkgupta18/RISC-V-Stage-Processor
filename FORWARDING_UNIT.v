`ifndef FORWARDING_UNIT_V
`define FORWARDING_UNIT_V
`timescale 1ns/1ps
/*
Forwarding Unit for 5-Stage Pipelined RISC-V Processor
Resolves RAW data hazards by forwarding ALU results from
EX/MEM and MEM/WB stages back to the EX stage inputs.

forward_A / forward_B encoding:
  2'b00 = No forwarding (use value from ID/EX register)
  2'b10 = Forward from EX/MEM pipeline register (1 instr ago)
  2'b01 = Forward from MEM/WB pipeline register (2 instrs ago)

Priority: EX/MEM forwarding takes precedence over MEM/WB
(more recent result wins when both match).
*/

module FORWARDING_UNIT(
    // Source register addresses in EX stage
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    
    // EX/MEM stage forwarding info
    input       ex_mem_regwrite,
    input [4:0] ex_mem_rd,
    
    // MEM/WB stage forwarding info
    input       mem_wb_regwrite,
    input [4:0] mem_wb_rd,
    
    // Forwarding select outputs
    output reg [1:0] forward_A,  // Select for ALU input 1 (rs1)
    output reg [1:0] forward_B   // Select for ALU input 2 (rs2)
);

    always @(*) begin
        // Default: no forwarding
        forward_A = 2'b00;
        forward_B = 2'b00;
        
        // ---- Forward A (rs1 source) ----
        
        // EX/MEM forwarding has priority (more recent result)
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_A = 2'b10;
        end
        // MEM/WB forwarding (only if EX/MEM doesn't already forward)
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_A = 2'b01;
        end
        
        // ---- Forward B (rs2 source) ----
        
        // EX/MEM forwarding has priority
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_B = 2'b10;
        end
        // MEM/WB forwarding
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_B = 2'b01;
        end
    end

endmodule
`endif
