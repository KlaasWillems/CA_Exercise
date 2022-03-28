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

   always@(*)begin
	if (regWriteMem == 1'b1 && MemRegisterRd == Rs1) begin
		ControlA = 2'b01;
	end else if (regWriteWB == 1'b1 && WBRegisterRd == Rs1) begin
		ControlA = 2'b10;
	end else begin
		ControlA = 2'b00;
	end
   end

   always@(*)begin
	if (regWriteMem == 1'b1 && MemRegisterRd == Rs2) begin
		ControlB = 2'b01;
	end else if (regWriteWB == 1'b1 && WBRegisterRd == Rs2) begin
		ControlB = 2'b10;
	end else begin
		ControlB = 2'b00;
	end
   end
endmodule

