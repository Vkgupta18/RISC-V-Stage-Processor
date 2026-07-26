`ifndef PIPE_DATAPATH_V
`define PIPE_DATAPATH_V
`timescale 1ns/1ps
/*
Pipeline Datapath for 5-Stage Pipelined RISC-V Processor
Contains all 4 pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
and the per-stage logic connecting all submodules.

Pipeline Stages:
  IF  - Instruction Fetch (PC + Instruction Memory)
  ID  - Instruction Decode (Register File Read + Immediate Gen + Control)
  EX  - Execute (ALU + Branch Unit + Forwarding)
  MEM - Memory Access (Data Memory Read/Write)
  WB  - Write-Back (to Register File)
*/

`include "INST_MEM.v"
`include "REG_FILE.v"
`include "IMM_GEN.v"
`include "PIPE_CONTROL.v"
`include "ALU.v"
`include "BRANCH_UNIT.v"
`include "FORWARDING_UNIT.v"
`include "HAZARD_DETECTION.v"
`include "DATA_MEM.v"

module PIPE_DATAPATH(
    input clock,
    input reset,
    // Debug outputs for testbench
    output [31:0] dbg_pc,
    output [31:0] dbg_if_id_instruction,
    output [31:0] dbg_if_id_pc,
    output [4:0]  dbg_id_ex_rd,
    output [4:0]  dbg_ex_mem_rd,
    output [4:0]  dbg_mem_wb_rd,
    output        dbg_ex_mem_regwrite,
    output        dbg_mem_wb_regwrite,
    output [31:0] dbg_ex_mem_alu_result,
    output [31:0] dbg_mem_wb_write_data,
    output        dbg_stall,
    output        dbg_flush
);

    // ================================================================
    //  PROGRAM COUNTER
    // ================================================================
    reg [31:0] PC;
    wire [31:0] PC_plus_4 = PC + 32'd4;
    wire [31:0] PC_next;
    
    // Branch/Jump control from EX stage
    wire        branch_taken;
    wire        jump_taken;
    wire [31:0] branch_target;
    
    // Hazard control
    wire        stall;
    wire        if_id_flush;
    wire        id_ex_flush;
    
    // PC MUX: branch target (if taken) or PC+4
    assign PC_next = (branch_taken || jump_taken) ? branch_target : PC_plus_4;
    
    // PC Register — freeze on stall (asynchronous reset)
    always @(posedge clock or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else if (!stall)
            PC <= PC_next;
        // else: PC stays frozen (stall)
    end
    
    assign dbg_pc = PC;

    // ================================================================
    //  IF STAGE: Instruction Fetch
    // ================================================================
    wire [31:0] if_instruction;
    
    INST_MEM instr_mem(
        .PC(PC),
        .reset(reset),
        .Instruction_Code(if_instruction)
    );

    // ================================================================
    //  IF/ID Pipeline Register
    //  BUG-6 FIX: Async reset separated from sync flush
    // ================================================================
    reg [31:0] if_id_PC;
    reg [31:0] if_id_instruction;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            if_id_PC          <= 32'b0;
            if_id_instruction <= 32'h00000013;  // NOP
        end
        else if (if_id_flush) begin
            if_id_PC          <= 32'b0;
            if_id_instruction <= 32'h00000013;  // NOP
        end
        else if (!stall) begin
            if_id_PC          <= PC;
            if_id_instruction <= if_instruction;
        end
        // else: frozen (stall)
    end
    
    assign dbg_if_id_instruction = if_id_instruction;
    assign dbg_if_id_pc          = if_id_PC;

    // ================================================================
    //  ID STAGE: Decode + Register Read + Immediate Gen + Control
    // ================================================================
    
    // Instruction field extraction
    wire [6:0] id_opcode = if_id_instruction[6:0];
    wire [4:0] id_rd     = if_id_instruction[11:7];
    wire [2:0] id_funct3 = if_id_instruction[14:12];
    wire [4:0] id_rs1    = if_id_instruction[19:15];
    wire [4:0] id_rs2    = if_id_instruction[24:20];
    wire [6:0] id_funct7 = if_id_instruction[31:25];
    
    // Control signals (generated in ID)
    wire [3:0] id_alu_control;
    wire       id_regwrite, id_alu_src, id_mem_read, id_mem_write;
    wire       id_mem_to_reg, id_branch, id_jump, id_alu_pc_src;
    
    PIPE_CONTROL control_unit(
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .alu_control(id_alu_control),
        .regwrite(id_regwrite),
        .alu_src(id_alu_src),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .jump(id_jump),
        .alu_pc_src(id_alu_pc_src)
    );
    
    // Immediate Generator
    wire [31:0] id_immediate;
    IMM_GEN imm_gen(
        .instruction(if_id_instruction),
        .immediate(id_immediate)
    );
    
    // Register File (WB writes happen here too — see WB stage wires below)
    wire [31:0] id_rs1_data, id_rs2_data;
    wire [4:0]  wb_rd;
    wire [31:0] wb_write_data;
    wire        wb_regwrite;
    
    REG_FILE reg_file(
        .read_reg_num1(id_rs1),
        .read_reg_num2(id_rs2),
        .write_reg(wb_rd),
        .write_data(wb_write_data),
        .read_data1(id_rs1_data),
        .read_data2(id_rs2_data),
        .regwrite(wb_regwrite),
        .clock(clock),
        .reset(reset)
    );

    // ================================================================
    //  ID/EX Pipeline Register
    //  BUG-6 FIX: Async reset separated from sync flush
    // ================================================================
    reg [31:0] id_ex_PC;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_immediate;
    reg [4:0]  id_ex_rd;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [2:0]  id_ex_funct3;
    reg [6:0]  id_ex_funct7;
    reg [6:0]  id_ex_opcode;
    // Control signals
    reg [3:0]  id_ex_alu_control;
    reg        id_ex_regwrite;
    reg        id_ex_alu_src;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_branch;
    reg        id_ex_jump;
    reg        id_ex_alu_pc_src;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            id_ex_PC          <= 32'b0;
            id_ex_rs1_data    <= 32'b0;
            id_ex_rs2_data    <= 32'b0;
            id_ex_immediate   <= 32'b0;
            id_ex_rd          <= 5'b0;
            id_ex_rs1         <= 5'b0;
            id_ex_rs2         <= 5'b0;
            id_ex_funct3      <= 3'b0;
            id_ex_funct7      <= 7'b0;
            id_ex_opcode      <= 7'b0;
            id_ex_alu_control <= 4'b0;
            id_ex_regwrite    <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_mem_read    <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_branch      <= 1'b0;
            id_ex_jump        <= 1'b0;
            id_ex_alu_pc_src  <= 1'b0;
        end
        else if (id_ex_flush) begin
            // Sync flush: insert NOP bubble (zero all control signals)
            id_ex_PC          <= 32'b0;
            id_ex_rs1_data    <= 32'b0;
            id_ex_rs2_data    <= 32'b0;
            id_ex_immediate   <= 32'b0;
            id_ex_rd          <= 5'b0;
            id_ex_rs1         <= 5'b0;
            id_ex_rs2         <= 5'b0;
            id_ex_funct3      <= 3'b0;
            id_ex_funct7      <= 7'b0;
            id_ex_opcode      <= 7'b0;
            id_ex_alu_control <= 4'b0;
            id_ex_regwrite    <= 1'b0;
            id_ex_alu_src     <= 1'b0;
            id_ex_mem_read    <= 1'b0;
            id_ex_mem_write   <= 1'b0;
            id_ex_mem_to_reg  <= 1'b0;
            id_ex_branch      <= 1'b0;
            id_ex_jump        <= 1'b0;
            id_ex_alu_pc_src  <= 1'b0;
        end
        else if (!stall) begin
            id_ex_PC          <= if_id_PC;
            id_ex_rs1_data    <= id_rs1_data;
            id_ex_rs2_data    <= id_rs2_data;
            id_ex_immediate   <= id_immediate;
            id_ex_rd          <= id_rd;
            id_ex_rs1         <= id_rs1;
            id_ex_rs2         <= id_rs2;
            id_ex_funct3      <= id_funct3;
            id_ex_funct7      <= id_funct7;
            id_ex_opcode      <= id_opcode;
            id_ex_alu_control <= id_alu_control;
            id_ex_regwrite    <= id_regwrite;
            id_ex_alu_src     <= id_alu_src;
            id_ex_mem_read    <= id_mem_read;
            id_ex_mem_write   <= id_mem_write;
            id_ex_mem_to_reg  <= id_mem_to_reg;
            id_ex_branch      <= id_branch;
            id_ex_jump        <= id_jump;
            id_ex_alu_pc_src  <= id_alu_pc_src;
        end
        // else: stall — ID/EX register is frozen
    end
    
    assign dbg_id_ex_rd = id_ex_rd;

    // ================================================================
    //  EX STAGE: Execute (ALU + Forwarding + Branch)
    // ================================================================
    
    // --- Forwarding Unit ---
    wire [1:0] forward_A, forward_B;
    // Forward declarations for EX/MEM and MEM/WB (driven in EX/MEM register block below)
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_regwrite;
    reg [31:0] ex_mem_alu_result;
    
    FORWARDING_UNIT fwd_unit(
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_regwrite(ex_mem_regwrite),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_regwrite(wb_regwrite),
        .mem_wb_rd(wb_rd),
        .forward_A(forward_A),
        .forward_B(forward_B)
    );  
    
    // --- Forwarding MUXes ---
    reg [31:0] ex_alu_in1_fwd;  // After forwarding, before alu_pc_src MUX
    reg [31:0] ex_rs2_fwd;      // After forwarding rs2
    
    always @(*) begin
        case(forward_A)
            2'b00:   ex_alu_in1_fwd = id_ex_rs1_data;        // No forwarding
            2'b10:   ex_alu_in1_fwd = ex_mem_alu_result;     // Forward from EX/MEM
            2'b01:   ex_alu_in1_fwd = wb_write_data;         // Forward from MEM/WB
            default: ex_alu_in1_fwd = id_ex_rs1_data;
        endcase
        
        case(forward_B)
            2'b00:   ex_rs2_fwd = id_ex_rs2_data;            // No forwarding
            2'b10:   ex_rs2_fwd = ex_mem_alu_result;          // Forward from EX/MEM
            2'b01:   ex_rs2_fwd = wb_write_data;              // Forward from MEM/WB
            default: ex_rs2_fwd = id_ex_rs2_data;
        endcase
    end
    
    // ALU input MUXes
    // Input 1: PC (AUIPC) or forwarded rs1
    wire [31:0] ex_alu_in1 = id_ex_alu_pc_src ? id_ex_PC : ex_alu_in1_fwd;
    // Input 2: Immediate (I-type, Load, Store, LUI, AUIPC, JALR) or forwarded rs2
    wire [31:0] ex_alu_in2 = id_ex_alu_src ? id_ex_immediate : ex_rs2_fwd;
    
    // --- ALU ---
    wire [31:0] ex_alu_result;
    wire        ex_zero_flag;
    
    ALU alu_unit(
        .in1(ex_alu_in1),
        .in2(ex_alu_in2),
        .alu_control(id_ex_alu_control),
        .alu_result(ex_alu_result),
        .zero_flag(ex_zero_flag)
    );
    
    // --- Branch Unit ---
    // For JALR, rs1 needs the forwarded value
    wire ex_branch_taken;
    wire [31:0] ex_branch_target;
    
    BRANCH_UNIT branch_unit(
        .PC(id_ex_PC),
        .immediate(id_ex_immediate),
        .rs1_data(ex_alu_in1_fwd),       // Forwarded rs1 for JALR target
        .opcode(id_ex_opcode),
        .funct3(id_ex_funct3),
        .branch(id_ex_branch),
        .jump(id_ex_jump),
        .zero_flag(ex_zero_flag),
        .alu_result(ex_alu_result),
        .branch_taken(ex_branch_taken),
        .branch_target(ex_branch_target)
    );
    
    // BUG-2 FIX: branch_taken from BRANCH_UNIT is already gated by branch/jump signals.
    // Use it directly instead of double-gating with && id_ex_branch.
    assign branch_taken  = ex_branch_taken;
    assign jump_taken    = 1'b0;  // Absorbed into branch_taken (jump sets branch_taken=1 inside BRANCH_UNIT)
    assign branch_target = ex_branch_target;
    
    // --- Hazard Detection Unit ---
    HAZARD_DETECTION hazard_unit(
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .branch_taken(branch_taken),
        .jump_taken(id_ex_jump),  // Still pass jump separately for hazard unit clarity
        .stall(stall),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );
    
    assign dbg_stall = stall;
    assign dbg_flush = if_id_flush;

    // ================================================================
    //  EX/MEM Pipeline Register
    // ================================================================
    reg [31:0] ex_mem_PC;
    reg [31:0] ex_mem_rs2_data;     // Store data (forwarded)
    reg [2:0]  ex_mem_funct3;
    // Control
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_to_reg;
    reg        ex_mem_jump;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ex_mem_PC          <= 32'b0;
            ex_mem_alu_result  <= 32'b0;
            ex_mem_rs2_data    <= 32'b0;
            ex_mem_rd          <= 5'b0;
            ex_mem_funct3      <= 3'b0;
            ex_mem_regwrite    <= 1'b0;
            ex_mem_mem_read    <= 1'b0;
            ex_mem_mem_write   <= 1'b0;
            ex_mem_mem_to_reg  <= 1'b0;
            ex_mem_jump        <= 1'b0;
        end
        else begin
            ex_mem_PC          <= id_ex_PC;
            ex_mem_alu_result  <= ex_alu_result;
            ex_mem_rs2_data    <= ex_rs2_fwd;       // Forwarded rs2 for stores
            ex_mem_rd          <= id_ex_rd;
            ex_mem_funct3      <= id_ex_funct3;
            ex_mem_regwrite    <= id_ex_regwrite;
            ex_mem_mem_read    <= id_ex_mem_read;
            ex_mem_mem_write   <= id_ex_mem_write;
            ex_mem_mem_to_reg  <= id_ex_mem_to_reg;
            ex_mem_jump        <= id_ex_jump;
        end
    end
    
    assign dbg_ex_mem_rd         = ex_mem_rd;
    assign dbg_ex_mem_regwrite   = ex_mem_regwrite;
    assign dbg_ex_mem_alu_result = ex_mem_alu_result;

    // ================================================================
    //  MEM STAGE: Data Memory Access
    // ================================================================
    wire [31:0] mem_read_data;
    
    DATA_MEM data_memory(
        .clock(clock),
        .reset(reset),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .funct3(ex_mem_funct3),
        .address(ex_mem_alu_result),
        .write_data(ex_mem_rs2_data),
        .read_data(mem_read_data)
    );

    // ================================================================
    //  MEM/WB Pipeline Register
    // ================================================================
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_data;
    reg [4:0]  mem_wb_rd;
    reg [31:0] mem_wb_PC;
    // Control
    reg        mem_wb_regwrite;
    reg        mem_wb_mem_to_reg;
    reg        mem_wb_jump;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_wb_alu_result  <= 32'b0;
            mem_wb_mem_data    <= 32'b0;
            mem_wb_rd          <= 5'b0;
            mem_wb_PC          <= 32'b0;
            mem_wb_regwrite    <= 1'b0;
            mem_wb_mem_to_reg  <= 1'b0;
            mem_wb_jump        <= 1'b0;
        end
        else begin
            mem_wb_alu_result  <= ex_mem_alu_result;
            mem_wb_mem_data    <= mem_read_data;
            mem_wb_rd          <= ex_mem_rd;
            mem_wb_PC          <= ex_mem_PC;
            mem_wb_regwrite    <= ex_mem_regwrite;
            mem_wb_mem_to_reg  <= ex_mem_mem_to_reg;
            mem_wb_jump        <= ex_mem_jump;
        end
    end

    // ================================================================
    //  WB STAGE: Write-Back
    // ================================================================
    // Write-back MUX: jump (PC+4), load (mem data), or ALU result
    assign wb_write_data = mem_wb_jump     ? (mem_wb_PC + 32'd4) :
                           mem_wb_mem_to_reg ? mem_wb_mem_data :
                           mem_wb_alu_result;
    assign wb_rd         = mem_wb_rd;
    assign wb_regwrite   = mem_wb_regwrite;
    
    assign dbg_mem_wb_rd         = mem_wb_rd;
    assign dbg_mem_wb_regwrite   = mem_wb_regwrite;
    assign dbg_mem_wb_write_data = wb_write_data;

endmodule
`endif
