module mux_3
  #(
   parameter integer DATA_W = 16
   )(
	input  wire [DATA_W-1:0] input_a, // register or immediate
	input  wire [DATA_W-1:0] input_b, // Mem stage
	input  wire [DATA_W-1:0] input_c, // WB stage
	input  wire [1:0]        select_a,
	output reg  [DATA_W-1:0] mux_out
   );

   always@(*)begin
	case(select_a)
		2'b00: mux_out = input_a;
		2'b01: mux_out = input_b;
		2'b10: mux_out = input_c;
		2'b11: mux_out = input_a;
	endcase
   end
endmodule
