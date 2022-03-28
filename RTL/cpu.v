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
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              EX_zero_flag, MEM_zero_flag;
wire [      63:0] EX_branch_pc,updated_pc,IF_PC,EX_jump_pc,ID_PC, EX_PC, MEM_branch_pc, MEM_jump_pc;
wire [      31:0] instruction, ID_INST;
wire [       1:0] ID_AluOp;
wire [       3:0] alu_control;
wire [4:0] Rs1, Rs2; 
wire              reg_dst,ID_Branch,ID_MemRead,ID_mem_2_reg,
                  ID_memwrite,ID_alusrc, ID_regwrite, ID_jump,
			EX_regwrite, EX_mem_2_reg,
			EX_Branch, EX_MemRead, EX_memwrite, EX_AluOp, EX_alusrc;
wire [1:0] forwardingControlA, forwardingControlB; 
wire [       4:0] regfile_waddr, EX_wb_reg, MEM_wb_reg, WB_wb_reg;
wire [      63:0] regfile_wdata,mem_data, WB_mem_data, alu_out, MEM_alu_out, WB_alu_out,
                  regfile_rdata_1,regfile_rdata_2, EX_rd2, MEM_rd2, EX_rd1, EX_immediate, alu_operand_2, alu_temp, alu_operand_1;
wire [1:0] EX_WB, MEM_WB, WB_WB;
wire [3:0] EX_M, MEM_M;
wire [2:0] EX_ex;
wire [9:0] EX_func73;
wire signed [63:0] immediate_extended;
wire [1:0] ID_WB = {ID_regwrite, ID_mem_2_reg}; // wire [1:0] EX_WB = {EX_regwrite, EX_mem_2_reg};
wire [3:0] ID_M = {ID_jump, ID_Branch, ID_MemRead, ID_memwrite}; // wire [2:0] EX_M = {EX_Branch, EX_MemRead, EX_memwrite};
wire [2:0] ID_ex = {ID_AluOp, ID_alusrc}; // wire [2:0] EX_ex = {EX_AluOp, EX_alusrc};
wire [9:0] ID_func73 = {ID_INST[31:25], ID_INST[14:12]};

// --------------------- IF Stage --------------
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (MEM_branch_pc ),
   .jump_pc   (MEM_jump_pc   ),
   .zero_flag (MEM_zero_flag ),
   .branch    (MEM_M[2]    ),
   .jump      (MEM_M[3]      ),
   .current_pc(IF_PC),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);

// The instruction memory.
sram_BW32 #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (IF_PC    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

// IF_ID Flipflops

reg_arstn_en#(
      .DATA_W(64)
   ) IF_ID_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (updated_pc   ),
      .en    (enable    ),
      .dout  (ID_PC)
   );
reg_arstn_en#(
      .DATA_W(32)
   ) IF_ID_FF2(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (instruction   ),
      .en    (enable    ),
      .dout  (ID_INST)
   );


// --------------------- ID Stage --------------

control_unit control_unit(
   .opcode   (ID_INST[6:0]),
   .alu_op   (ID_AluOp          ),
   .reg_dst  (reg_dst         ),
   .branch   (ID_Branch          ),
   .mem_read (ID_MemRead        ),
   .mem_2_reg(ID_mem_2_reg       ),
   .mem_write(ID_memwrite       ),
   .alu_src  (ID_alusrc         ),
   .reg_write(ID_regwrite       ),
   .jump     (ID_jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(WB_WB[1]         ),
   .raddr_1  (ID_INST[19:15]),
   .raddr_2  (ID_INST[24:20]),
   .waddr    (WB_wb_reg ),
   .wdata    (regfile_wdata),
   .rdata_1  (regfile_rdata_1),
   .rdata_2  (regfile_rdata_2)
);

immediate_extend_unit immediate_extend_u(
    .instruction         (ID_INST),
    .immediate_extended  (immediate_extended)
);

reg_arstn_en#(
      .DATA_W(2)
   ) ID_EX_FF1(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_WB),
      .en    (enable    ),
      .dout  (EX_WB)
   );

reg_arstn_en#(
      .DATA_W(4)
   ) ID_EX_FF2(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_M),
      .en    (enable    ),
      .dout  (EX_M)
   );

reg_arstn_en#(
      .DATA_W(3)
   ) ID_EX_FF3(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_ex),
      .en    (enable    ),
      .dout  (EX_ex)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF4(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_PC   ),
      .en    (enable    ),
      .dout  (EX_PC)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF5(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  regfile_rdata_1 ),
      .en    (enable    ),
      .dout  (EX_rd1)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF6(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  regfile_rdata_2 ),
      .en    (enable    ),
      .dout  (EX_rd2)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) ID_EX_FF7(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  immediate_extended ),
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

reg_arstn_en#( // RF Address 1
      .DATA_W(5)
   ) ID_EX_FF99(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_INST[19:15]),
      .en    (enable    ),
      .dout  (Rs1)
   );


reg_arstn_en#( // RF Address 2
      .DATA_W(5)
   ) ID_EX_FF98(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (ID_INST[24:20]),
      .en    (enable    ),
      .dout  (Rs2)
   );
// --------------------- EX Stage --------------

alu_control alu_ctrl(
   .func7       (EX_func73[9:3]),
   .func3          (EX_func73[2:0]),
   .alu_op         (EX_ex[2:1] ),
   .alu_control    (alu_control       )
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_operand_1 ),
   .alu_in_1 (alu_operand_2   ),
   .alu_ctrl (alu_control     ),
   .alu_out  (alu_out         ),
   .zero_flag(EX_zero_flag       ),
   .overflow (                )
);

branch_unit#(
   .DATA_W(64)
)branch_unit(
   .updated_pc         (EX_PC        ),
   .immediate_extended (EX_immediate),
   .branch_pc          (EX_branch_pc         ),
   .jump_pc            (EX_jump_pc           )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (EX_immediate),
   .input_b (EX_rd2),
   .select_a(EX_ex[0]),
   .mux_out (alu_temp)
);

mux_3 #( // operand 1
	.DATA_W(64)
) forwardingMux1 (
   .input_a (EX_rd1),
   .input_b (MEM_alu_out),
   .input_c (regfile_wdata),
   .select_a(forwardingControlA),
   .mux_out (alu_operand_1)
);

mux_3 #( // operand 2
	.DATA_W(64)
) forwardingMux2 (
   .input_a (alu_temp),
   .input_b (MEM_alu_out),
   .input_c (regfile_wdata),
   .select_a(forwardingControlB),
   .mux_out (alu_operand_2)
);

forwardingUnit #(.AddressSize(5))
forwardingUnit1 (
	.Rs1(Rs1),
	.Rs2(Rs2),
	.MemRegisterRd(MEM_wb_reg),
	.WBRegisterRd(WB_wb_reg),
	.regWriteWB(MEM_WB[1]),
	.regWriteMem(WB_WB[1]),
	.ControlA(forwardingControlA),
	.ControlB(forwardingControlB)
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
      .DATA_W(64)
   ) EX_MEM_FF3(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_branch_pc),
      .en    (enable    ),
      .dout  (MEM_branch_pc)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) EX_MEM_FF4(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (EX_jump_pc),
      .en    (enable    ),
      .dout  (MEM_jump_pc)
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
      .din   (alu_out),
      .en    (enable    ),
      .dout  (MEM_alu_out)
   );

reg_arstn_en#(
      .DATA_W(64)
   ) EX_MEM_FF7(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (  EX_rd2 ),
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

// --------------------- Mem Stage --------------


// The data memory.
sram_BW64 #(
   .ADDR_W(10),
   .DATA_W(64)
) data_memory(
   .clk      (clk            ),
   .addr     (MEM_alu_out        ),
   .wen      (MEM_M[0]      ),
   .ren      (MEM_M[1]       ),
   .wdata    (MEM_rd2),
   .rdata    (mem_data       ),   
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
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
      .din   (mem_data),
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
   .mux_out  (regfile_wdata)
);



endmodule


