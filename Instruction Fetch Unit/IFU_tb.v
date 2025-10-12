`include "IFU.v"
module stimulus();
    reg CLOCK, RESET;
    reg branch_taken;
    reg jump;
    reg [31:0] branch_target;
    wire [31:0] OUTPUT;
    wire [31:0] PC;

    // Initializing IFU module (no branches/jumps in this tb)
    IFU IFU_module(
        CLOCK,
        RESET,
        branch_taken,
        jump,
        branch_target,
        OUTPUT,
        PC
    );

    // Setting up waveform
    initial begin
        $dumpfile("IFU_output_wave.vcd");
        // Restrict dump scope to reduce file size
        $dumpvars(0, stimulus.CLOCK, stimulus.RESET, OUTPUT);
    end

    // Monitoring the changes in values
    initial
    $monitor($time, "CLOCK = %b, RESET = %b, PC = %0d, Instruction Code = %h", CLOCK, RESET, PC, OUTPUT);

    // Initializing reset and control inputs
    initial begin
        RESET = 1'b0;
        branch_taken = 1'b0;
        jump = 1'b0;
        branch_target = 32'd0;
        #20 RESET = 1'b1;
        #200 RESET = 1'b0;
        #100 RESET = 1'b1;
    end

    // Initializing clock
    initial
    begin
        CLOCK = 1;
        forever #20 CLOCK = ~CLOCK;
    end

    initial begin
        #240 $dumpoff; // stop dumping early
        #160 $finish;
    end

endmodule