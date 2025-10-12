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

    //  When reset is triggered, initialize registers deterministically using a loop
    always @(posedge reset) begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_memory[i] <= i[31:0];
        end
    end

    // Reads are combinational; enforce x0 hardwired to zero per RISC-V
    assign read_data1 = (read_reg_num1 == 5'd0) ? 32'h0 : reg_memory[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'd0) ? 32'h0 : reg_memory[read_reg_num2];

    // On clock edge, write when enabled; prevent writes to x0
    always @(posedge clock) begin
        if (regwrite && (write_reg != 5'd0)) begin
            reg_memory[write_reg] <= write_data;
        end     
    end

endmodule