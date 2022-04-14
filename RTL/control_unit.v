// module: Control
// Function: Generates the control signals for each one of the datapath resources

module control_unit(
      input wire [6:0] opcode_2, // for the second issue (addi instructions)
      input wire [6:0] opcode_1,
      input wire [2:0] func3,
      input wire branchTaken,
      input wire regEqual,
      output reg [1:0] alu_op,
      output reg branch,
      output reg mem_read,
      output reg mem_2_reg,
      output reg mem_write,
      output reg alu_src,
      output reg reg_write_1,
      output reg reg_write_2,
      output reg jump,
      output reg flush
   );

   // RISC-V opcode[6:0] (see RISC-V greensheet)
   parameter integer ALU_R      = 7'b0110011;
   parameter integer ALU_I      = 7'b0010011;
   parameter integer BRANCH     = 7'b1100011;
   parameter integer JUMP       = 7'b1101111;
   parameter integer LOAD       = 7'b0000011;
   parameter integer STORE      = 7'b0100011;
   parameter integer BEQ = 3'b000;
   parameter integer BNE = 3'b001;

   // RISC-V ALUOp[1:0] (see book Figure 4.12)
   parameter [1:0] ADD_OPCODE     = 2'b00;
   parameter [1:0] SUB_OPCODE     = 2'b01;
   parameter [1:0] R_TYPE_OPCODE  = 2'b10;

   // addi second issue
   always @(*) begin
      case(opcode_2)
	ALU_I: reg_write_2 = 1'b1;
	default: reg_write_2 = 1'b0;
      endcase
   end

   //The behavior of the control unit can be found in Chapter 4, Figure 4.18
   always @(*) begin

   case(opcode_1)
         ALU_R:begin
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write_1 = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
	    flush     = 1'b0;
	end
	
	ALU_I:begin
            alu_src   = 1'b1;
            mem_2_reg = 1'b0;
            reg_write_1 = 1'b1;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE;
            jump      = 1'b0;	
	    flush     = 1'b0;
	end

	BRANCH:begin
		if ((regEqual != branchTaken && func3 == BEQ) || (regEqual == branchTaken && func3 == BNE)) begin // flush if prediction was wrong
         alu_src   = 1'b0;
         mem_2_reg = 1'b0;
         reg_write_1 = 1'b0;
         mem_read  = 1'b0;
         mem_write = 1'b0;
         branch    = 1'b1;
         alu_op    = SUB_OPCODE;
         jump      = 1'b0;
         flush     = 1'b1;
		end else begin
         alu_src   = 1'b0;
         mem_2_reg = 1'b0;
         reg_write_1 = 1'b0;
         mem_read  = 1'b0;
         mem_write = 1'b0;
         branch    = 1'b0;
         alu_op    = SUB_OPCODE;
         jump      = 1'b0;
         flush     = 1'b0;
		end
	end

	STORE:begin
         alu_src   = 1'b1;
         mem_2_reg = 1'b0;
         reg_write_1 = 1'b0;
         mem_read  = 1'b0;
         mem_write = 1'b1;
         branch    = 1'b0;
         alu_op    = ADD_OPCODE;
         jump      = 1'b0;
         flush     = 1'b0;
	end
	
	LOAD:begin
         alu_src   = 1'b1;
         mem_2_reg = 1'b1;
         reg_write_1 = 1'b1;
         mem_read  = 1'b1;
         mem_write = 1'b0;
         branch    = 1'b0;
         alu_op    = ADD_OPCODE;
         jump      = 1'b0;
         flush     = 1'b0;
	end
	
	JUMP:begin
		alu_src   = 1'b0;
		mem_2_reg = 1'b0;
		reg_write_1 = 1'b1; // Write PC + 4 to Rd register 
		mem_read  = 1'b0;
		mem_write = 1'b0;
		branch    = 1'b0;
		alu_op    = ADD_OPCODE;
		jump      = 1'b1;
		flush     = 1'b1; // Always flush with jump instruction, Address is not store in branch prediction table
	end
         
   // nop if instruction is not recognized
   default:begin
	 alu_src   = 1'b0;
	 mem_2_reg = 1'b0;
	 reg_write_1 = 1'b0;
	 mem_read  = 1'b0;
	 mem_write = 1'b0;
	 branch    = 1'b0;
	 alu_op    = R_TYPE_OPCODE;
	 jump      = 1'b0;
	 flush     = 1'b0;
   end

      endcase
   end

endmodule



