`ifndef INST_MEM_V
`define INST_MEM_V
`timescale 1ns/1ps
/* 
Instruction Memory for 5-Stage Pipelined RISC-V Processor
4KB byte-addressable memory. All locations initialized to NOP (0x00000013)
to prevent x-propagation after program end.

Test program exercises all pipeline hazard types:
  - Back-to-back RAW data hazards (forwarding test)
  - Load-use hazard (stall test)
  - Branch taken/not-taken (flush test)
  - JAL and JALR
  - LUI/AUIPC
  - Shift instructions (SLL, SRL, SRA, SLLI)
  - Signed comparisons and backward branches
*/
module INST_MEM(
    input [31:0] PC,
    input reset,
    output [31:0] Instruction_Code
);
    reg [7:0] Memory [0:4095];

    // Word-aligned address
    wire [11:0] word_addr = {PC[11:2], 2'b00};
    
    // Read 32-bit instruction (little-endian)
    assign Instruction_Code = {Memory[word_addr+3], Memory[word_addr+2], Memory[word_addr+1], Memory[word_addr]};

    integer j;
    initial begin
        // BUG-7 FIX: Zero-fill entire memory with NOPs first to prevent x-propagation
        // NOP = ADDI x0, x0, 0 = 0x00000013. We fill bytes: 0x13, 0x00, 0x00, 0x00 (little-endian)
        for (j = 0; j < 4096; j = j + 4) begin
            Memory[j]   = 8'h13;
            Memory[j+1] = 8'h00;
            Memory[j+2] = 8'h00;
            Memory[j+3] = 8'h00;
        end
        
        // ============================================================
        // Pipeline Test Program (24 real instructions + NOP padding)
        // ============================================================
        
        // --- Test 1: Basic ALU (ADDI) ---
        // PC=0x00:   ADDI x1, x0, 10    -> x1 = 10
        {Memory[3],  Memory[2],  Memory[1],  Memory[0]}  = 32'h00A00093;
        
        // --- Test 2: Back-to-back RAW hazard (forwarding from EX/MEM) ---
        // PC=0x04: ADDI x2, x0, 20      -> x2 = 20
        {Memory[7],  Memory[6],  Memory[5],  Memory[4]}  = 32'h01400113;
        
        // PC=0x08: ADD  x3, x1, x2      -> x3 = 10 + 20 = 30  (EX/MEM fwd x2, MEM/WB fwd x1)
        {Memory[11], Memory[10], Memory[9],  Memory[8]}  = 32'h002081B3;
        
        // --- Test 3: Another RAW (forwarding from EX/MEM for x3) ---
        // PC=0x0C: ADDI x4, x3, 5       -> x4 = 30 + 5 = 35
        {Memory[15], Memory[14], Memory[13], Memory[12]} = 32'h00518213;
        
        // --- Test 4: Store & Load ---
        // PC=0x10: SW   x4, 0(x0)       -> mem[0] = 35
        {Memory[19], Memory[18], Memory[17], Memory[16]} = 32'h00402023;
        
        // PC=0x14: LW   x5, 0(x0)       -> x5 = 35
        {Memory[23], Memory[22], Memory[21], Memory[20]} = 32'h00002283;
        
        // --- Test 5: Load-use hazard (must stall 1 cycle) ---
        // PC=0x18: ADD  x6, x5, x1      -> x6 = 35 + 10 = 45
        {Memory[27], Memory[26], Memory[25], Memory[24]} = 32'h00128333;
        
        // --- Test 6: Branch NOT taken ---
        // PC=0x1C: BNE  x1, x1, 12      -> NOT taken (x1 == x1)
        {Memory[31], Memory[30], Memory[29], Memory[28]} = 32'h00109663;
        
        // --- Test 7: Instruction after branch-not-taken (should execute) ---
        // PC=0x20: ADDI x7, x0, 77      -> x7 = 77
        {Memory[35], Memory[34], Memory[33], Memory[32]} = 32'h04D00393;
        
        // --- Test 8: Branch TAKEN ---
        // PC=0x24: BEQ  x1, x1, 8       -> TAKEN, jump to PC=0x2C
        {Memory[39], Memory[38], Memory[37], Memory[36]} = 32'h00108463;
        
        // PC=0x28: ADDI x8, x0, 99      -> SKIPPED (flushed by branch)
        {Memory[43], Memory[42], Memory[41], Memory[40]} = 32'h06300413;

        // --- Test 9: Branch target ---
        // PC=0x2C: ADDI x9, x0, 42      -> x9 = 42
        {Memory[47], Memory[46], Memory[45], Memory[44]} = 32'h02A00493;
        
        // --- Test 10: LUI ---
        // PC=0x30: LUI  x10, 0xDEADB    -> x10 = 0xDEADB000
        {Memory[51], Memory[50], Memory[49], Memory[48]} = 32'hDEADB537;
        
        // --- Test 11: AUIPC ---
        // PC=0x34: AUIPC x11, 0x00001   -> x11 = 0x34 + 0x1000 = 0x1034
        {Memory[55], Memory[54], Memory[53], Memory[52]} = 32'h00001597;
        
        // --- Test 12: JAL ---
        // PC=0x38: JAL  x12, 8          -> x12 = 0x3C (PC+4), jump to PC=0x40
        {Memory[59], Memory[58], Memory[57], Memory[56]} = 32'h0080066F;
        
        // PC=0x3C: ADDI x13, x0, 88     -> SKIPPED (flushed by JAL)
        {Memory[63], Memory[62], Memory[61], Memory[60]} = 32'h05800693;
        
        // --- Test 13: JAL target & SUB test ---
        // PC=0x40: SUB  x14, x6, x1     -> x14 = 45 - 10 = 35
        {Memory[67], Memory[66], Memory[65], Memory[64]} = 32'h40130733;
        
        // --- Test 14: SLT test ---
        // PC=0x44: SLT  x15, x1, x2     -> x15 = (10 < 20) ? 1 : 0 = 1
        {Memory[71], Memory[70], Memory[69], Memory[68]} = 32'h0020A7B3;
        
        // --- Test 15: ANDI ---
        // PC=0x48: ANDI x16, x7, 0xFF   -> x16 = 77 & 255 = 77
        {Memory[75], Memory[74], Memory[73], Memory[72]} = 32'h0FF3F813;
        
        // --- Test 16: ORI ---
        // PC=0x4C: ORI  x17, x0, 0x0F   -> x17 = 0 | 15 = 15
        {Memory[79], Memory[78], Memory[77], Memory[76]} = 32'h00F06893;

        // --- Test 17: SLLI (shift left logical immediate) ---
        // PC=0x50: SLLI x18, x1, 3      -> x18 = 10 << 3 = 80 (0x50)
        // Encoding: funct7=0000000, shamt=00011, rs1=x1(00001), funct3=001, rd=x18(10010), opcode=0010011
        {Memory[83], Memory[82], Memory[81], Memory[80]} = 32'h00309913;

        // --- Test 18: SRL (shift right logical) ---
        // PC=0x54: ADDI x19, x0, 2      -> x19 = 2 (shift amount)
        {Memory[87], Memory[86], Memory[85], Memory[84]} = 32'h00200993;
        
        // PC=0x58: SRL  x20, x18, x19   -> x20 = 80 >> 2 = 20 (0x14)
        // Encoding: funct7=0000000, rs2=x19(10011), rs1=x18(10010), funct3=101, rd=x20(10100), opcode=0110011
        {Memory[91], Memory[90], Memory[89], Memory[88]} = 32'h01395A33;

        // --- Test 19: SRAI (shift right arithmetic on negative number) ---
        // PC=0x5C: LUI  x21, 0xFFFFF    -> x21 = 0xFFFFF000 (negative upper bits)
        {Memory[95], Memory[94], Memory[93], Memory[92]} = 32'hFFFFFAB7;
        
        // PC=0x60: ADDI x21, x21, -1    -> x21 = 0xFFFFF000 + (-1) = 0xFFFFEFFF
        // Encoding: imm=111111111111 (-1), rs1=x21(10101), funct3=000, rd=x21(10101), opcode=0010011
        {Memory[99], Memory[98], Memory[97], Memory[96]} = 32'hFFFa8A93;

        // PC=0x64: SRAI x22, x21, 4     -> x22 = 0xFFFFEFFF >>> 4 = 0xFFFFFEFF (sign-extended)
        // Encoding: funct7=0100000, shamt=00100, rs1=x21(10101), funct3=101, rd=x22(10110), opcode=0010011
        {Memory[103], Memory[102], Memory[101], Memory[100]} = 32'h404ADB13;

        // --- Test 20: JALR ---
        // PC=0x68: ADDI x23, x0, 0x74   -> x23 = 0x74 (target address for JALR)
        {Memory[107], Memory[106], Memory[105], Memory[104]} = 32'h07400B93;
        
        // PC=0x6C: JALR x24, x23, 0     -> x24 = 0x70 (PC+4), jump to x23+0 = 0x74
        // Encoding: imm=000000000000, rs1=x23(10111), funct3=000, rd=x24(11000), opcode=1100111
        {Memory[111], Memory[110], Memory[109], Memory[108]} = 32'h000B8C67;
        
        // PC=0x70: ADDI x25, x0, 111    -> SKIPPED (flushed by JALR)
        {Memory[115], Memory[114], Memory[113], Memory[112]} = 32'h06F00C93;
        
        // --- Test 21: JALR target & backward branch setup ---
        // PC=0x74: ADDI x25, x0, 3      -> x25 = 3 (loop counter)
        {Memory[119], Memory[118], Memory[117], Memory[116]} = 32'h00300C93;
        
        // --- Test 22: Backward branch (loop) ---
        // PC=0x78: ADDI x25, x25, -1    -> x25 = x25 - 1
        // Encoding: imm=111111111111 (-1), rs1=x25(11001), funct3=000, rd=x25(11001), opcode=0010011
        {Memory[123], Memory[122], Memory[121], Memory[120]} = 32'hFFFC8C93;
        
        // PC=0x7C: BNE  x25, x0, -4     -> if x25 != 0, jump back to PC=0x78 (offset = -4)
        // B-type: imm[12|10:5]=1111111, rs2=x0(00000), rs1=x25(11001), funct3=001, imm[4:1|11]=1110_1, opcode=1100011
        {Memory[127], Memory[126], Memory[125], Memory[124]} = 32'hFE0C9EE3;
        
        // --- Test 23: XOR test ---
        // PC=0x80: XORI x26, x7, 0xFF   -> x26 = 77 ^ 255 = 178 (0xB2)
        // Encoding: imm=0x0FF, rs1=x7(00111), funct3=100, rd=x26(11010), opcode=0010011
        {Memory[131], Memory[130], Memory[129], Memory[128]} = 32'h0FF3CD13;
        
        // --- NOP padding (end of program) ---
        // PC=0x84 onwards: NOPs (already filled by zero-init loop above)
    end
endmodule
`endif
