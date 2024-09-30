
// Pipeline MIPS32 module
module pipe_MIPS32 (clk1, clk2); 

    input clk1, clk2; // Two-phase clock 
    
    // Slack Storage
    reg [31:0] PC, IF_ID_IR, IF_ID_NPC; 
    reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm; 
    reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; 
    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B; 
    reg EX_MEM_cond; 
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD; 
    
    reg [31:0] Reg [0:31]; // Register bank (32 x 32) 
    reg [31:0] Mem [0:1023]; // 1024 x 32 memory
    
    // For Arithmetic and Logic Instructions with register operand
    parameter ADD=6'b000000;
    parameter SUB=6'b000001;
    parameter AND=6'b000010; 
    parameter OR=6'b000011;
    parameter SLT=6'b000100;
    parameter MUL=6'b000101;
    
    // For Arithmetic and Logic Instructions with immediate operand
    parameter ADDI=6'b001010;
    parameter SUBI=6'b001011;
    parameter SLTI=6'b001100;
    
    // For Branch Intstructions
    parameter BNEQZ=6'b001101;
    parameter BEQZ=6'b001110;
    
    // For Miscellaneous Instructions
    parameter HLT=6'b111111;
    parameter LW=6'b001000;
    parameter SW=6'b001001;
    
    //For Arithmetic Logic Unit
    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, HALT=3'b101; 
    
    reg HALTED; 
	// Set after HLT instruction is completed (in WB(Register write-back) stage) 
 
    reg TAKEN_BRANCH; 
	// Required to disable instructions after branch
    
    always @(posedge clk1) // IF Stage: Instruction Fetch 
        if (HALTED == 0) 
          begin 
            if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) 
              begin 
                IF_ID_IR      <= #2 Mem[EX_MEM_ALUOut]; 
                TAKEN_BRANCH  <= #2 1'b1; 
                IF_ID_NPC     <= #2 EX_MEM_ALUOut + 1; 
                PC            <= #2 EX_MEM_ALUOut + 1; 
              end
            else 
              begin 
                IF_ID_IR   <= #2 Mem[PC]; 
                IF_ID_NPC  <= #2 PC + 1; 
                PC         <= #2 PC + 1; 
              end 
          end
    
    always @(posedge clk2) // ID Stage: Instruction Decode/Register Fetch 
        if (HALTED == 0) 
          begin
            if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
            else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]]; // "rs"
 
            if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0; 
            else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]]; // "rt" 
 
            ID_EX_NPC <= #2 IF_ID_NPC; 
            ID_EX_IR  <= #2 IF_ID_IR; 
            ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};
            
            case (IF_ID_IR[31:26]) 
                ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= #2 RR_ALU; 
                ADDI,SUBI,SLTI:         ID_EX_type <= #2 RM_ALU; 
                LW:                     ID_EX_type <= #2 LOAD; 
                SW:                     ID_EX_type <= #2 STORE; 
                BNEQZ,BEQZ:             ID_EX_type <= #2 BRANCH; 
                HLT:                    ID_EX_type <= #2 HALT; 
                default:                ID_EX_type <= #2 HALT; 
                                        // For Invalid opcode
            endcase
          end
    
    always @(posedge clk1) // EX Stage: Execution/Effective Address Calculation 
        if (HALTED == 0)
          begin 
            EX_MEM_type <= #2 ID_EX_type; 
            EX_MEM_IR <= #2 ID_EX_IR; 
            TAKEN_BRANCH <= #2 0; 
         
            case (ID_EX_type) 
                RR_ALU: begin 
                          case (ID_EX_IR[31:26]) // "opcode" 
                              ADD: EX_MEM_ALUOut     <= #2 ID_EX_A + ID_EX_B; 
                              SUB: EX_MEM_ALUOut     <= #2 ID_EX_A - ID_EX_B; 
                              AND: EX_MEM_ALUOut     <= #2 ID_EX_A & ID_EX_B; 
                              OR:  EX_MEM_ALUOut     <= #2 ID_EX_A | ID_EX_B; 
                              SLT: EX_MEM_ALUOut     <= #2 ID_EX_A < ID_EX_B; 
                              MUL: EX_MEM_ALUOut     <= #2 ID_EX_A * ID_EX_B; 
                              default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
                          endcase
                        end
                RM_ALU: begin 
                          case (ID_EX_IR[31:26]) // "opcode" 
                              ADDI: EX_MEM_ALUOut    <= #2 ID_EX_A + ID_EX_Imm; 
                              SUBI: EX_MEM_ALUOut    <= #2 ID_EX_A - ID_EX_Imm; 
                              SLTI: EX_MEM_ALUOut    <= #2 ID_EX_A < ID_EX_Imm; 
                              default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
                          endcase
                        end
                LOAD, STORE: begin 
                               EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; 
                               EX_MEM_B      <= #2 ID_EX_B; 
                             end
                BRANCH: begin 
                          EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm; 
                          EX_MEM_cond   <= #2 (ID_EX_A == 0); 
                        end 
            endcase
          end
    
    always @(posedge clk2) // MEM Stage: Memory Access/Branch Completion
        if (HALTED == 0)
          begin
            MEM_WB_type <= #2 EX_MEM_type; 
            MEM_WB_IR   <= #2 EX_MEM_IR; 
 
            case (EX_MEM_type) 
              RR_ALU, RM_ALU: MEM_WB_ALUOut <= #2 EX_MEM_ALUOut; 
              LOAD:           MEM_WB_LMD    <= #2 Mem[EX_MEM_ALUOut]; 
              STORE:          if (TAKEN_BRANCH == 0) // Disable write 
                                  Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B; 
            endcase
          end
    
    always @(posedge clk1) // WB Stage: Register Write-Back 
        if (TAKEN_BRANCH == 0) // Disable write if branch taken 
          begin
            case (MEM_WB_type) 
                RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // "rd" 
                RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // "rt" 
                LOAD: Reg[MEM_WB_IR[20:16]]   <= #2 MEM_WB_LMD; // "rt" 
                HALT: HALTED <= #2 1'b1; 
            endcase
          end 
endmodule
