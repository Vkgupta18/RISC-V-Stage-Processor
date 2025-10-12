module CONTROL(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [3:0] alu_control,
    output reg regwrite,
    output reg alu_src,         // New: 0=register, 1=immediate
    output reg mem_read,        // New: enable memory read
    output reg mem_write,       // New: enable memory write
    output reg mem_to_reg,      // New: 0=ALU result, 1=memory data
    output reg branch,          // New: is branch instruction
    output reg jump             // New: is jump instruction
);

    // Opcode definitions
    localparam R_TYPE  = 7'b0110011;
    localparam I_TYPE  = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam BRANCH  = 7'b1100011;
    localparam JAL     = 7'b1101111;
    localparam JALR    = 7'b1100111;
    localparam LUI     = 7'b0110111;
    localparam AUIPC   = 7'b0010111;

    always @(*) begin
        // Default outputs to avoid latches and ensure safe fallbacks
        // Default values
        regwrite = 1'b0;
        alu_src = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        alu_control = 4'b1111; // Invalid operation
        
        case(opcode)
            R_TYPE: begin
                regwrite = 1'b1;
                alu_src = 1'b0;  // Use rs2
                case({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_control = 4'b0010; // ADD
                    {7'b0100000, 3'b000}: alu_control = 4'b0100; // SUB
                    {7'b0000000, 3'b001}: alu_control = 4'b0011; // SLL
                    {7'b0000000, 3'b010}: alu_control = 4'b1000; // SLT
                    {7'b0000000, 3'b011}: alu_control = 4'b1001; // SLTU
                    {7'b0000000, 3'b100}: alu_control = 4'b0111; // XOR
                    {7'b0000000, 3'b101}: alu_control = 4'b0101; // SRL
                    {7'b0100000, 3'b101}: alu_control = 4'b1010; // SRA
                    {7'b0000000, 3'b110}: alu_control = 4'b0001; // OR
                    {7'b0000000, 3'b111}: alu_control = 4'b0000; // AND
                    {7'b0000001, 3'b000}: alu_control = 4'b0110; // MUL
                    default: alu_control = 4'b1111;
                endcase
            end
            
            I_TYPE: begin
                regwrite = 1'b1;
                alu_src = 1'b1;  // Use immediate
                case(funct3)
                    3'b000: alu_control = 4'b0010; // ADDI
                    3'b010: alu_control = 4'b1000; // SLTI
                    3'b011: alu_control = 4'b1001; // SLTIU
                    3'b100: alu_control = 4'b0111; // XORI
                    3'b110: alu_control = 4'b0001; // ORI
                    3'b111: alu_control = 4'b0000; // ANDI
                    3'b001: alu_control = 4'b0011; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_control = 4'b0101; // SRLI
                        else
                            alu_control = 4'b1010; // SRAI
                    end
                    default: alu_control = 4'b1111;
                endcase
            end
            
            LOAD: begin
                regwrite = 1'b1;
                alu_src = 1'b1;      // Use immediate for address calculation
                mem_read = 1'b1;
                mem_to_reg = 1'b1;   // Write memory data to register
                alu_control = 4'b0010; // ADD for address calculation
            end
            
            STORE: begin
                alu_src = 1'b1;      // Use immediate for address calculation
                mem_write = 1'b1;
                alu_control = 4'b0010; // ADD for address calculation
            end
            
            BRANCH: begin
                alu_src = 1'b0;      // Compare registers
                branch = 1'b1;
                case(funct3)
                    3'b000: alu_control = 4'b0100; // BEQ (SUB to check zero)
                    3'b001: alu_control = 4'b0100; // BNE (SUB to check zero)
                    3'b100: alu_control = 4'b1000; // BLT (SLT)
                    3'b101: alu_control = 4'b1000; // BGE (SLT)
                    3'b110: alu_control = 4'b1001; // BLTU (SLTU)
                    3'b111: alu_control = 4'b1001; // BGEU (SLTU)
                    default: alu_control = 4'b1111;
                endcase
            end
            
            JAL, JALR: begin
                regwrite = 1'b1;
                jump = 1'b1;
                alu_control = 4'b0010; // ADD for PC+4
            end
            
            LUI: begin
                regwrite = 1'b1;
                alu_src = 1'b1;
                alu_control = 4'b1011; // Pass immediate
            end
            
            AUIPC: begin
                regwrite = 1'b1;
                alu_src = 1'b1;
                alu_control = 4'b1100; // PC + immediate
            end
            
            default: begin
                // All outputs already set to default
            end
        endcase
    end
endmodule