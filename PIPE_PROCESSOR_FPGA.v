`ifndef PIPE_PROCESSOR_FPGA_V
`define PIPE_PROCESSOR_FPGA_V
`timescale 1ns/1ps
// ============================================================================
//  PIPE_PROCESSOR_FPGA — Basys 3 FPGA Top-Level Wrapper
// ============================================================================
//  Wraps the pipelined RISC-V processor and exposes internal debug signals
//  to Basys 3 peripherals:
//    - 16 LEDs:         Show selected 16-bit slice of debug data
//    - 16 Switches:     SW[1:0] select which debug word to display
//                       SW[2] selects upper/lower 16-bit half of 32-bit values
//    - 4-digit 7-seg:   Shows the same selected 16-bit value in hexadecimal
//    - Center button:   Active-high reset (active-high matches Basys 3 buttons)
//    - 100 MHz clock:   On-board oscillator at W5
//
//  Debug display MUX (SW[1:0]):
//    2'b00 → PC            (32-bit, SW[2] selects half)
//    2'b01 → Instruction   (32-bit, SW[2] selects half)
//    2'b10 → ALU result    (32-bit, SW[2] selects half)
//    2'b11 → Write-back    (32-bit, SW[2] selects half)
//
//  LED[15] = stall, LED[14] = flush  (always visible, overriding the mux)
// ============================================================================

`include "PIPE_PROCESSOR.v"

module PIPE_PROCESSOR_FPGA(
    input         clk,           // 100 MHz board oscillator (W5)
    input         reset,         // Center push-button BTNC (U18), active-high
    input  [15:0] sw,            // 16 slide switches
    output [15:0] LED,           // 16 LEDs
    output [6:0]  seg,           // Seven-segment cathode signals (active-low)
    output        dp,            // Seven-segment decimal point  (active-low)
    output [3:0]  an             // Seven-segment anode signals  (active-low)
);

    // ====================================================================
    //  Instantiate the pipelined processor
    // ====================================================================
    // The debug wires inside PIPE_PROCESSOR are internal, so we access
    // them via hierarchical references to the datapath instance.
    // Alternatively, we promote them. Here we promote by connecting the
    // PIPE_DATAPATH directly.

    // --- Internal debug wires (directly connected from datapath) ---
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

    // Instantiate the datapath directly (bypassing PIPE_PROCESSOR shell)
    // so all debug ports are properly wired as real connections.
    PIPE_DATAPATH datapath(
        .clock                  (clk),
        .reset                  (reset),
        .dbg_pc                 (dbg_pc),
        .dbg_if_id_instruction  (dbg_if_id_instruction),
        .dbg_if_id_pc           (dbg_if_id_pc),
        .dbg_id_ex_rd           (dbg_id_ex_rd),
        .dbg_ex_mem_rd          (dbg_ex_mem_rd),
        .dbg_mem_wb_rd          (dbg_mem_wb_rd),
        .dbg_ex_mem_regwrite    (dbg_ex_mem_regwrite),
        .dbg_mem_wb_regwrite    (dbg_mem_wb_regwrite),
        .dbg_ex_mem_alu_result  (dbg_ex_mem_alu_result),
        .dbg_mem_wb_write_data  (dbg_mem_wb_write_data),
        .dbg_stall              (dbg_stall),
        .dbg_flush              (dbg_flush)
    );

    // ====================================================================
    //  Debug Display MUX
    // ====================================================================
    //  SW[1:0] selects which 32-bit debug word
    //  SW[2]   selects upper (1) or lower (0) 16-bit half
    reg [31:0] dbg_selected_word;
    wire [15:0] dbg_display_half;

    always @(*) begin
        case (sw[1:0])
            2'b00:   dbg_selected_word = dbg_pc;
            2'b01:   dbg_selected_word = dbg_if_id_instruction;
            2'b10:   dbg_selected_word = dbg_ex_mem_alu_result;
            2'b11:   dbg_selected_word = dbg_mem_wb_write_data;
            default: dbg_selected_word = 32'b0;
        endcase
    end

    assign dbg_display_half = sw[2] ? dbg_selected_word[31:16]
                                    : dbg_selected_word[15:0];

    // ====================================================================
    //  LED Output
    // ====================================================================
    //  LED[13:0] = lower 14 bits of selected display half
    //  LED[14]   = pipeline flush indicator
    //  LED[15]   = pipeline stall indicator
    assign LED[13:0] = dbg_display_half[13:0];
    assign LED[14]   = dbg_flush;
    assign LED[15]   = dbg_stall;

    // ====================================================================
    //  Seven-Segment Display Driver
    // ====================================================================
    //  Multiplexes 4 hex digits from dbg_display_half across the 4 anodes
    //  using a refresh counter (~1 kHz from 100 MHz → 17-bit counter).

    reg [16:0] refresh_counter;          // 100 MHz / 2^17 ≈ 763 Hz refresh
    wire [1:0] digit_sel = refresh_counter[16:15];

    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 17'b0;
        else
            refresh_counter <= refresh_counter + 1'b1;
    end

    // Select which hex nibble to display
    reg [3:0] hex_nibble;
    always @(*) begin
        case (digit_sel)
            2'b00:   hex_nibble = dbg_display_half[3:0];
            2'b01:   hex_nibble = dbg_display_half[7:4];
            2'b10:   hex_nibble = dbg_display_half[11:8];
            2'b11:   hex_nibble = dbg_display_half[15:12];
            default: hex_nibble = 4'b0;
        endcase
    end

    // Anode driver (active-low: 0 = ON)
    reg [3:0] an_reg;
    always @(*) begin
        case (digit_sel)
            2'b00:   an_reg = 4'b1110;   // Rightmost digit active
            2'b01:   an_reg = 4'b1101;
            2'b10:   an_reg = 4'b1011;
            2'b11:   an_reg = 4'b0111;   // Leftmost digit active
            default: an_reg = 4'b1111;   // All off
        endcase
    end
    assign an = an_reg;

    // Hex-to-seven-segment decoder (active-low cathodes: 0 = segment ON)
    //  Segment encoding: seg[6:0] = {g, f, e, d, c, b, a}
    reg [6:0] seg_reg;
    always @(*) begin
        case (hex_nibble)
            4'h0: seg_reg = 7'b1000000;   // 0
            4'h1: seg_reg = 7'b1111001;   // 1
            4'h2: seg_reg = 7'b0100100;   // 2
            4'h3: seg_reg = 7'b0110000;   // 3
            4'h4: seg_reg = 7'b0011001;   // 4
            4'h5: seg_reg = 7'b0010010;   // 5
            4'h6: seg_reg = 7'b0000010;   // 6
            4'h7: seg_reg = 7'b1111000;   // 7
            4'h8: seg_reg = 7'b0000000;   // 8
            4'h9: seg_reg = 7'b0010000;   // 9
            4'hA: seg_reg = 7'b0001000;   // A
            4'hB: seg_reg = 7'b0000011;   // b
            4'hC: seg_reg = 7'b1000110;   // C
            4'hD: seg_reg = 7'b0100001;   // d
            4'hE: seg_reg = 7'b0000110;   // E
            4'hF: seg_reg = 7'b0001110;   // F
            default: seg_reg = 7'b1111111; // All off
        endcase
    end
    assign seg = seg_reg;

    // Decimal point always off
    assign dp = 1'b1;

endmodule
`endif
