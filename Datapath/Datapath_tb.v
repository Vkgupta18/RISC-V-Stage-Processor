`include "DATAPATH.v"

module stimulus ();

    reg [4:0] read_reg_num1;
    reg [4:0] read_reg_num2;
    reg [4:0] write_reg;
    reg [3:0] alu_control;
    reg regwrite;
    reg clock;
    reg reset;

    DATAPATH DATAPATH_module( 
     read_reg_num1,
     read_reg_num2,
     write_reg,
     alu_control,
     regwrite,
     clock,
     reset,
     zero_flag);

    initial begin
        $dumpfile("output_wave.vcd");
        // Limit waveform scope to key signals
        $dumpvars(0, stimulus.clock, stimulus.reset);
        $dumpvars(0, DATAPATH_module.read_reg_num1, DATAPATH_module.read_reg_num2, DATAPATH_module.write_reg);
        $dumpvars(0, DATAPATH_module.zero_flag);
    end

    initial begin
        reset = 1;
        #20 reset = 0;
    end

    initial begin
        #25 read_reg_num1 = 0; read_reg_num2 = 0;
        #20 read_reg_num1 = 0; read_reg_num2 = 1;
        #20 read_reg_num1 = 0; read_reg_num2 = 1;
        #20 read_reg_num1 = 1; read_reg_num2 = 2;
    end

    initial begin
        regwrite = 0;
        #10
        regwrite = 1;
    end

    initial begin
        alu_control = 4'b0010;
    end

    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end

    initial begin
        #120 $dumpoff; // stop dumping early to shrink VCD
        #80  $finish;
    end
    
endmodule