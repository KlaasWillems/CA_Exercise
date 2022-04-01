// Configurable register for variable width with enable

module reg_arstn_en_with_reset#(
parameter integer DATA_W     = 20,
parameter integer PRESET_VAL = 0
   )(
      input                  clk,
      input 		     reset,
      input                  arst_n,
      input                  en,
      input  [ DATA_W-1:0]   din,
      output [ DATA_W-1:0]   dout
);

reg [DATA_W-1:0] r,nxt;
reg zero;

always@(posedge clk, negedge arst_n)begin
   if(arst_n==0)begin
      r <= PRESET_VAL;
   end else begin
      r <= nxt;
   end
end

always@(*) begin
   if(en == 1'b1)begin
	if (reset == 1'b1) begin
		nxt = 0;
	end else begin
      		nxt = din;
	end
   end else begin
      nxt = r;
   end
end

assign dout = r;

endmodule
