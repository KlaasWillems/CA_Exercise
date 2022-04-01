module forwardingUnit 
  #(
   parameter integer AddressSize = 5
   )(
	input  wire [AddressSize-1:0] Rs1,
	input  wire [AddressSize-1:0] Rs2,
	input  wire [AddressSize-1:0] MemRegisterRd,
	input  wire [AddressSize-1:0] WBRegisterRd,
	input wire regWriteWB,
	input wire regWriteMem,
	output reg [1:0] ControlA,
	output reg [1:0] ControlB
   );
parameter [4:0] ZERO_ADDRESS = 5'b00000;
wire booleanA, booleanB;
assign booleanA = regWriteMem == 1'b1 && MemRegisterRd == Rs1 && MemRegisterRd != ZERO_ADDRESS;
assign booleanB = regWriteMem == 1'b1 && MemRegisterRd == Rs2 && MemRegisterRd != ZERO_ADDRESS;

   always@(*)begin
	if (booleanA == 1'b1) begin
		ControlA = 2'b01;
	end else if (regWriteWB == 1'b1 && WBRegisterRd == Rs1 && WBRegisterRd != ZERO_ADDRESS && booleanA == 1'b0) begin
		ControlA = 2'b10;
	end else begin
		ControlA = 2'b00;
	end
   end

   always@(*)begin
	if (booleanB == 1'b1) begin
		ControlB = 2'b01;
	end else if (regWriteWB == 1'b1 && WBRegisterRd == Rs2 && WBRegisterRd != ZERO_ADDRESS && booleanB == 1'b0) begin
		ControlB = 2'b10;
	end else begin
		ControlB = 2'b00;
	end
   end
endmodule

