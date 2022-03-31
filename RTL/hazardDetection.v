// Configurable register for variable width

module hazardDetection(
      input                  MemRead,
      input  [4:0]           Rd,
      input  [4:0]   Rs1,
      input  [4:0]   Rs2,
      output hazard
);

always @(*) begin
	if (MemRead == 1'b1 && (Rs1 == Rd or Rs2 == Rd)) begin
		hazard = 1'b1;
	end else begin
		hazard = 1'b0;
	end
end

endmodule
