	`timescale 1ns/1ps
/*
A register file can read two registers and write in to one register. 
The RISC V register file contains total of 32 registers each of size 32-bit. 
Hence 5-bits are used to specify the register numbers that are to be read or written. 
*/

/*
Register Read: Register file always outputs the contents of the register corresponding to read register numbers specified. 
Reading a register is not dependent on any other signals.

Register Write: Register writes are controlled by a control signal RegWrite.  
Additionally the register file has a clock signal. 
The write should happen if RegWrite signal is made 1 and if there is positive edge of clock. 
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

    reg [31:0] reg_memory [31:0]; // 32 memory locations each 32 bits wide
    integer i=0;

    //  When reset is triggered, we initialize the registers with some values
    always @(posedge reset)
    begin
        // Bear with me for now, I tried using loops, but it won't work
        // Just duct-taping this for now
         reg_memory[0] = 32'd0;
         reg_memory[1] = 32'd1;
         reg_memory[2] = 32'd2;
         reg_memory[3] = 32'd3;
         reg_memory[4] = 32'd4;
         reg_memory[5] = 32'd5;
         reg_memory[6] = 32'd6;
         reg_memory[7] = 32'd7;
         reg_memory[8] = 32'd8;
         reg_memory[9] = 32'd9;
         reg_memory[10] = 32'd10;
         reg_memory[11] = 32'd11;
         reg_memory[12] = 32'd12;
         reg_memory[13] = 32'd13;
         reg_memory[14] = 32'd14;
         reg_memory[15] = 32'd15;
         reg_memory[16] = 32'd16;
         reg_memory[17] = 32'd17;
         reg_memory[18] = 32'd18;
         reg_memory[19] = 32'd19;
         reg_memory[20] = 32'd20;
         reg_memory[21] = 32'd21;
         reg_memory[22] = 32'd22;
         reg_memory[23] = 32'd23;
         reg_memory[24] = 32'd24;
         reg_memory[25] = 32'd25;
		 reg_memory[26] = 32'd26;
         reg_memory[27] = 32'd27;
         reg_memory[28] = 32'd28;
         reg_memory[29] = 32'd29;
         reg_memory[30] = 32'd30;
         reg_memory[31] = 32'd31;

    end

    // The register file will always output the values corresponding to read register numbers 
    // Register 0 (x0) is hardwired to zero per RISC-V specification
    assign read_data1 = (read_reg_num1 == 5'b0) ? 32'd0 : reg_memory[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'b0) ? 32'd0 : reg_memory[read_reg_num2];

    // If clock edge is positive and regwrite is 1, we write data to specified register
    // Prevent writes to register 0 (x0 must always be zero)
    always @(posedge clock)
    begin
        if (regwrite && (write_reg != 5'b0)) begin
            reg_memory[write_reg] <= write_data;
        end     
    end

endmodule
