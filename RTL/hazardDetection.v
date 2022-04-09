// Configurable register for variable width

module hazardDetection(
      input wire [6:0] ID_OPCODE,
      input wire ID_memWrite, // IF store instruction in ID stage
      input wire EX_memRead, // IF load instruction in EX stage
      input [4:0] EX_Rd, // Write back register in EX stage
      input [4:0] ID_Rs1, // Operands 1 and 2 in ID stage
      input [4:0] ID_Rs2,
      output reg hazard // stall signal
);

parameter integer STORE = 7'b0100011;
parameter integer BRANCH = 7'b1100011; 

wire ld_sd_exception = ID_memWrite == 1'b1 && EX_memRead == 1'b1 && ID_Rs2 == EX_Rd; // If this is 1, we are performing a copy (load followed by a store). In this case we shouldn't stall, since we can forward the result.
wire basic_hazard = EX_memRead == 1'b1 && ((ID_Rs1 == EX_Rd) || (ID_Rs2 == EX_Rd)); // load followed by an operation that requires the result from the load
wire use_branch = ID_OPCODE == BRANCH && ((ID_Rs1 == EX_Rd) || (ID_Rs2 == EX_Rd)); // addi x1, x1, 1; beq x1, ... In case a branch instruction uses data from previous instruction

always @(*) begin
	if ((basic_hazard == 1'b1 && ld_sd_exception == 1'b0) || use_branch == 1'b1) begin
		hazard = 1'b1;
	end else begin
		hazard = 1'b0;
	end
end

endmodule
