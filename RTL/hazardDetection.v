// Configurable register for variable width

module hazardDetection(
      input wire [6:0] ID_OPCODE,
      input wire ID_memWrite,
      input wire EX_memRead,
      input [4:0] Rd,
      input [4:0] Rs1,
      input [4:0] Rs2,
      output reg hazard
);

parameter integer STORE = 7'b0100011;
parameter integer BRANCH = 7'b1100011; 

wire ld_sd_exception = ID_memWrite == 1'b1 && EX_memRead == 1'b1 && Rs2 == Rd; // If this is 1, we are performing a copy (load followed by a store). In this case we shouldn't stall, since we can forward the result.
wire basic_hazard = EX_memRead == 1'b1 && ((Rs1 == Rd) || (Rs2 == Rd));
wire use_branch = ID_OPCODE == BRANCH && ((Rs1 == Rd) || (Rs2 == Rd)); // addi x1, x1, 1; beq x1, ... stalling in case a branch instruction uses data from previous instruction

always @(*) begin
	if ((basic_hazard == 1'b1 && ld_sd_exception == 1'b0) || use_branch == 1'b1) begin
		hazard = 1'b1;
	end else begin
		hazard = 1'b0;
	end
end

endmodule
