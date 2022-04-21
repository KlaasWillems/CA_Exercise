//Module: CPU
//Function: CPU is the top design of the RISC-V processor


//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0] wdata_ext, 
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire [31:0] rdata_ext, 
		output wire [63:0] rdata_ext_2

   );

// Parameters
parameter [1:0] twoBitZero = 2'b00;
parameter [3:0] fourBitZero = 4'b0000;
parameter [2:0] threeBitZero = 3'b000;

// Branch Prediction and Hazard Signals
wire IF_branchPredictionBoolean, ID_branchPredictionBoolean;
wire [63:0] predictionPC;
wire [63:0] ID_operand1, ID_operand2;
wire hazardBoolean, flush, hazardEnable, regEqual, notFlushed, WB_M_1;
wire [1:0] forwardingControlA, forwardingControlB;
wire forwardingControlC, forwardingControlD, forwardingControlE; 

// WB Signals
wire [4:0] WB_wb_reg;
wire [63:0] WB_mem_data, WB_alu_out, WB_regfile_wdata;

// MEM Signals
wire [4:0] MEM_Rs2, MEM_wb_reg; 
wire MEM_zero_flag;
wire [63:0] MEM_mem_data, MEM_rd2, MEM_rd, MEM_alu_out;

// EX Signals
wire [3:0] EX_alu_control;
wire [4:0] EX_Rs1, EX_Rs2, EX_wb_reg;
wire [63:0] EX_branch_pc, EX_updated_PC, EX_jump_pc, EX_alu_out, EX_out, EX_rd2, EX_rd1, EX_immediate, EX_alu_operand_2, EX_alu_temp, EX_alu_operand_1;

// EX Control Signals
wire [1:0] EX_WB, MEM_WB, WB_WB, ID_WB1;
wire [3:0] EX_M, MEM_M, ID_M1;
wire [2:0] EX_ex, ID_ex1;
wire [9:0] EX_func73;
wire EX_zero_flag;

// ID Signals
wire signed [63:0] ID_immediate_extended;
wire [63:0] ID_updated_PC, ID_Branch_PC, ID_Jump_PC, ID_regfile_rdata_1, ID_regfile_rdata_2;
wire [1:0] ID_AluOp;
wire [31:0] ID_INST;

// ID Control Signals
wire ID_Branch, ID_MemRead, ID_mem_2_reg, ID_memwrite, ID_alusrc, ID_regwrite, ID_jump;
wire [1:0] ID_WB = {ID_regwrite, ID_mem_2_reg}; // wire [1:0] EX_WB = {EX_regwrite, EX_mem_2_reg};
wire [3:0] ID_M = {ID_jump, ID_Branch, ID_MemRead, ID_memwrite}; // wire [2:0] EX_M = {EX_Jump, EX_Branch, EX_MemRead, EX_memwrite};
wire [2:0] ID_ex = {ID_AluOp, ID_alusrc}; // wire [2:0] EX_ex = {EX_AluOp, EX_alusrc};
wire [9:0] ID_func73 = {ID_INST[31:25], ID_INST[14:12]};

// IF Signals
wire [31:0] instruction;
wire [63:0] IF_updated_pc, IF_PC;

// Issue 2 signals (addi pipeline)
wire ID_regwrite_2, EX_regwrite_2, WB_regwrite_2;
wire [31:0] instruction_2, ID_INST_2;
wire [63:0] ID_regfile_rdata_3, ID_immediate_extended_2, EX_rd3, EX_immediate_2, EX_alu_out_2, WB_alu_out_2;
wire [4:0] EX_wb_reg_2, WB_wb_reg_2;

// --------------------- Assignments ---------------------

assign hazardEnable = enable & !hazardBoolean; // Stall
assign notFlushed = !flush;
assign regEqual = ID_operand1 == ID_operand2;

// --------------------- IF Stage ---------------------

branchPredictionTable BPT1(
    .clk(clk),
    .arst_n(arst_n),
    .IF_PC(IF_PC),
    .branchPC(ID_Jump_PC), 
    .notFlushed(notFlushed), 
    .ID_INST(ID_INST),
    .predictedBranchPC(predictionPC),
    .branchTaken(IF_branchPredictionBoolean)
    );

pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (ID_Branch_PC), // When prediction was wrong, either take the branch or load in PC + 4
   .jump_pc   (ID_Jump_PC), // Always PC + im - 4
   .branch    (ID_Branch),
   .jump      (ID_jump),
   .current_pc(IF_PC),
   .enable    (hazardEnable),
   .IF_INST_OPCODE (instruction[6:0]),
   .updated_pc(IF_updated_pc),
   .branchTaken (IF_branchPredictionBoolean),
   .predictionPC (predictionPC)
);

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (IF_PC         ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .addr_ext (addr_ext      ), 
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     ), 
   .rdata_nxt(instruction_2 ) 
);

reg_arstn_en#(
      .DATA_W(64)
   ) IF_ID_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (IF_updated_pc   ),
      .en    (hazardEnable    ),
      .dout  (ID_updated_PC)
   );
reg_arstn_en_with_reset#(
      .DATA_W(32)
   ) IF_ID_FF2(
      .clk   (clk       ),
      .reset (flush),
      .arst_n(arst_n    ),
      .din   (instruction   ),
      .en    (hazardEnable),
      .dout  (ID_INST)
   );
reg_arstn_en_with_reset#(
      .DATA_W(32)
   ) IF_ID_FF3(
      .clk   (clk       ),
      .reset (flush),
      .arst_n(arst_n    ),
      .din   (instruction_2   ),
      .en    (hazardEnable),
      .dout  (ID_INST_2)
   );
reg_arstn_en_with_reset#(
      .DATA_W(1)
   ) IF_ID_FF4(
      .clk   (clk),
      .reset (flush),
      .arst_n(arst_n),
      .din   (IF_branchPredictionBoolean),
      .en    (hazardEnable),
      .dout  (ID_branchPredictionBoolean)
   );

// --------------------- ID Stage --------------

mux_2 #( // operand 1
	.DATA_W(64)
) forwardingMux3 (
   .input_a (MEM_alu_out),
   .input_b (ID_regfile_rdata_1),
   .select_a(forwardingControlC),
   .mux_out (ID_operand1)
);

mux_2 #( // operand 2
	.DATA_W(64)
) forwardingMux4 (
   .input_a (MEM_alu_out),
   .input_b (ID_regfile_rdata_2),
   .select_a(forwardingControlD),
   .mux_out (ID_operand2)
);

hazardDetection hazardDetectionModule(
   .ID_OPCODE(ID_INST[6:0]),
	.ID_memWrite(ID_M[0]),
	.EX_memRead(EX_M[1]),
	.EX_Rd(EX_wb_reg),
	.ID_Rs1(ID_INST[19:15]),
	.ID_Rs2(ID_INST[24:20]),
	.hazard(hazardBoolean)
);

control_unit control_unit(
   .opcode_2   (ID_INST_2[6:0]),
   .opcode_1   (ID_INST[6:0]),
   .func3 (ID_INST[14:12]),
   .branchTaken (ID_branchPredictionBoolean),
   .regEqual (regEqual),
   .alu_op   (ID_AluOp),
   .branch   (ID_Branch),
   .mem_read (ID_MemRead),
   .mem_2_reg(ID_mem_2_reg),
   .mem_write(ID_memwrite),
   .alu_src  (ID_alusrc),
   .reg_write_1(ID_regwrite),
   .reg_write_2(ID_regwrite_2),
   .jump     (ID_jump),
   .flush    (flush)
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (ID_updated_PC),
   .immediate_extended (ID_immediate_extended),
   .func3              (ID_INST[14:12]),
   .regEqual           (regEqual),
   .branchPrediction   (ID_branchPredictionBoolean),
   .branch_pc          (ID_Branch_PC),
   .jump_pc            (ID_Jump_PC)
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk),
   .arst_n   (arst_n),
   .reg_write_1 (WB_WB[1]),
   .reg_write_2 (WB_regwrite_2),
   .raddr_1  (ID_INST[19:15]),
   .raddr_2  (ID_INST[24:20]),
   .raddr_3  (ID_INST_2[19:15]),
   .waddr_1    (WB_wb_reg),
   .waddr_2    (WB_wb_reg_2),
   .wdata_1    (WB_regfile_wdata),
   .wdata_2    (WB_alu_out_2),
   .rdata_1  (ID_regfile_rdata_1),
   .rdata_2  (ID_regfile_rdata_2),
   .rdata_3  (ID_regfile_rdata_3)
);

immediate_extend_unit immediate_extend_u1(
    .instruction         (ID_INST),
    .immediate_extended  (ID_immediate_extended)
);

immediate_extend_unit immediate_extend_u2( // For the addi pipeline
    .instruction         (ID_INST_2),
    .immediate_extended  (ID_immediate_extended_2)
);


mux_2 #(
   .DATA_W(2)
) hazardMux1 (
   .input_a (twoBitZero),
   .input_b (ID_WB),
   .select_a(hazardBoolean),
   .mux_out (ID_WB1)
);

reg_arstn_en#(
      .DATA_W(2)
   ) ID_EX_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_WB1),
      .en    (enable    ),
      .dout  (EX_WB)
   );

mux_2 #(
   .DATA_W(4)
) hazardMux2 (
   .input_a (fourBitZero),
   .input_b (ID_M),
   .select_a(hazardBoolean),
   .mux_out (ID_M1)
);

reg_arstn_en#(
      .DATA_W(4)
   ) ID_EX_FF2(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_M1),
      .en    (enable    ),
      .dout  (EX_M)
   );

mux_2 #(
   .DATA_W(3)
) hazardMux3 (
   .input_a (threeBitZero),
   .input_b (ID_ex),
   .select_a(hazardBoolean),
   .mux_out (ID_ex1)
);

reg_arstn_en#(
      .DATA_W(3)
   ) ID_EX_FF3(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_ex1),
      .en    (enable    ),
      .dout  (EX_ex)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF5(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_regfile_rdata_1),
      .en    (enable    ),
      .dout  (EX_rd1)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF6(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_regfile_rdata_2),
      .en    (enable    ),
      .dout  (EX_rd2)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF7(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_immediate_extended),
      .en    (enable    ),
      .dout  (EX_immediate)
   );

reg_arstn_en#(
      .DATA_W(10)
   ) ID_EX_FF8(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  ID_func73 ),
      .en    (enable    ),
      .dout  (EX_func73)
   );

reg_arstn_en#(
      .DATA_W(5)
   ) ID_EX_FF9(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  ID_INST[11:7] ),
      .en    (enable    ),
      .dout  (EX_wb_reg)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF10(
      .clk   (clk),
      .arst_n(arst_n),
      .din   (ID_updated_PC),
      .en    (enable),
      .dout  (EX_updated_PC)
   );


reg_arstn_en#( // RF Address 1
      .DATA_W(5)
   ) ID_EX_FF11(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_INST[19:15]),
      .en    (enable    ),
      .dout  (EX_Rs1)
   );

reg_arstn_en#( // RF Address 2
      .DATA_W(5)
   ) ID_EX_FF12(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_INST[24:20]),
      .en    (enable    ),
      .dout  (EX_Rs2)
   );

reg_arstn_en#( // WB address addi pipeline
      .DATA_W(5)
   ) ID_EX_FF13(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_INST_2[11:7]),
      .en    (enable    ),
      .dout  (EX_wb_reg_2)
   );

reg_arstn_en#( // regwrite addi pipeline
      .DATA_W(1)
   ) ID_EX_FF14(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_regwrite_2),
      .en    (enable    ),
      .dout  (EX_regwrite_2)
   );

reg_arstn_en#( // Operand 1 for addi pipeline
      .DATA_W(64)
   ) ID_EX_FF15(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_regfile_rdata_3),
      .en    (enable    ),
      .dout  (EX_rd3)
   );

reg_arstn_en#( // Operand 1 for addi pipeline
      .DATA_W(64)
   ) ID_EX_FF16(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_immediate_extended_2),
      .en    (enable    ),
      .dout  (EX_immediate_2)
   );


// --------------------- EX Stage --------------

imm_alu #(.DATA_W(64)) issue2_alu(
   .alu_in_0 (EX_rd3),
   .alu_in_1 (EX_immediate_2),
   .alu_out  (EX_alu_out_2)
);

alu_control alu_ctrl(
   .func7       (EX_func73[9:3]),
   .func3          (EX_func73[2:0]),
   .alu_op         (EX_ex[2:1] ),
   .alu_control    (EX_alu_control)
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (EX_alu_operand_1),
   .alu_in_1 (EX_alu_operand_2),
   .alu_ctrl (EX_alu_control),
   .alu_out  (EX_alu_out         ),
   .zero_flag(EX_zero_flag       ),
   .overflow (                )
);

mux_3 #( // operand 2
	.DATA_W(64)
) forwardingMux2 (
   .input_a (EX_rd2),
   .input_b (MEM_alu_out),
   .input_c (WB_regfile_wdata),
   .select_a(forwardingControlB),
   .mux_out (EX_alu_temp)
);

mux_2 #( // operand 2
   .DATA_W(64)
) alu_operand_mux (
   .input_a (EX_immediate),
   .input_b (EX_alu_temp),
   .select_a(EX_ex[0]),
   .mux_out (EX_alu_operand_2)
);

mux_3 #( // operand 1
	.DATA_W(64)
) forwardingMux1 (
   .input_a (EX_rd1),
   .input_b (MEM_alu_out),
   .input_c (WB_regfile_wdata),
   .select_a(forwardingControlA),
   .mux_out (EX_alu_operand_1)
);

mux_2 #(
   .DATA_W(64)
) alu_out_mux (
   .input_a (EX_updated_PC),
   .input_b (EX_alu_out),
   .select_a(EX_M[3]), // Jump signal. If 1, Write PC+4 to registers
   .mux_out (EX_out)
);

forwardingUnit #(.AddressSize(5))
forwardingUnit1 (
   .IDRs1(ID_INST[19:15]),
   .IDRs2(ID_INST[24:20]),
	.EXRs1(EX_Rs1),
	.EXRs2(EX_Rs2),
   .MEMRs2(MEM_Rs2),
	.MemRegisterRd(MEM_wb_reg),
	.WBRegisterRd(WB_wb_reg),
	.regWriteWB(WB_WB[1]),
	.WB_mem_read(WB_M_1),
	.regWriteMem(MEM_WB[1]),
	.ControlA(forwardingControlA),
	.ControlB(forwardingControlB),
   .ControlC(forwardingControlC),
   .ControlD(forwardingControlD),
   .ControlE(forwardingControlE)
);

reg_arstn_en#(
      .DATA_W(2)
   ) EX_MEM_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_WB),
      .en    (enable    ),
      .dout  (MEM_WB)
   );

reg_arstn_en#(
      .DATA_W(4)
   ) EX_MEM_FF2(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_M),
      .en    (enable    ),
      .dout  (MEM_M)
   );


reg_arstn_en#(
      .DATA_W(1)
   ) EX_MEM_FF5(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_zero_flag),
      .en    (enable    ),
      .dout  (MEM_zero_flag)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) EX_MEM_FF6(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_out),
      .en    (enable    ),
      .dout  (MEM_alu_out)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) EX_MEM_FF7(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_alu_temp),
      .en    (enable    ),
      .dout  (MEM_rd2)
   );

reg_arstn_en#(
      .DATA_W(5)
   ) EX_MEM_FF8(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_wb_reg),
      .en    (enable    ),
      .dout  (MEM_wb_reg)
   );

reg_arstn_en#( // RF Address 2
      .DATA_W(5)
   ) EX_MEM_FF9(
      .clk   (clk),
      .arst_n(arst_n),
      .din   (EX_Rs2),
      .en    (enable),
      .dout  (MEM_Rs2)
   );

reg_arstn_en#( // wb address addi pipeline
      .DATA_W(5)
   ) EX_MEM_FF10(
      .clk   (clk),
      .arst_n(arst_n),
      .din   (EX_wb_reg_2),
      .en    (enable),
      .dout  (WB_wb_reg_2)
   );

reg_arstn_en#( // wb address addi pipeline
      .DATA_W(64)
   ) EX_MEM_FF11(
      .clk   (clk),
      .arst_n(arst_n),
      .din   (EX_alu_out_2),
      .en    (enable),
      .dout  (WB_alu_out_2)
   );

reg_arstn_en#( // wb address addi pipeline
      .DATA_W(1)
   ) EX_MEM_FF12(
      .clk   (clk),
      .arst_n(arst_n),
      .din   (EX_regwrite_2),
      .en    (enable),
      .dout  (WB_regwrite_2)
   );


// --------------------- Mem Stage --------------

mux_2 #(
   .DATA_W(64)
) data_memory_mux (
   .input_a (WB_mem_data),
   .input_b (MEM_rd2),
   .select_a(forwardingControlE), // load store forwarding
   .mux_out (MEM_rd)
);


// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (MEM_alu_out        ),
   .wen      (MEM_M[0]      ),
   .ren      (MEM_M[1]       ),
   .wdata    (MEM_rd),
   .rdata    (MEM_mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);

reg_arstn_en#(
      .DATA_W(1)
   ) MEM_WB_FF5(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_M[1]),
      .en    (enable    ),
      .dout  (WB_M_1)
   );

reg_arstn_en#(
      .DATA_W(2)
   ) MEM_WB_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_WB),
      .en    (enable    ),
      .dout  (WB_WB)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) MEM_WB_FF2(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_mem_data),
      .en    (enable    ),
      .dout  (WB_mem_data)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) MEM_WB_FF3(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_alu_out),
      .en    (enable    ),
      .dout  (WB_alu_out)
   );

reg_arstn_en#(
      .DATA_W(5)
   ) MEM_WB_FF4(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (MEM_wb_reg),
      .en    (enable    ),
      .dout  (WB_wb_reg)
   );

// --------------------- WB Stage --------------

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (WB_mem_data     ),
   .input_b  (WB_alu_out      ),
   .select_a (WB_WB[0]    ),
   .mux_out  (WB_regfile_wdata)
);



endmodule


