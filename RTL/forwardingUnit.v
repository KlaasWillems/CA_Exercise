module forwardingUnit 
  #(
   parameter integer AddressSize = 5
   )(
	input wire [AddressSize-1:0] IDRs1, // for the check if equal logic (for branches)
	input wire [AddressSize-1:0] IDRs2, 
	input wire [AddressSize-1:0] EXRs1,
	input wire [AddressSize-1:0] EXRs2,
	input wire [AddressSize-1:0] MEMRs2,
	input wire [AddressSize-1:0] MemRegisterRd,
	input wire [AddressSize-1:0] WBRegisterRd,
	input wire regWriteWB,
	input wire regWriteMem,
	input wire WB_mem_read,
	output reg [1:0] ControlA, // forwarding to operand 1 of the ALU
	output reg [1:0] ControlB, // forwaring to operand 2 of the ALU
	output reg ControlC, // forwarding to operand 1 of the compare logic in the ID stage
	output reg ControlD, // forwarding to operand 2 of the compare logic in the ID stage
	output reg ControlE // load, store forwarding
   );

parameter [4:0] ZERO_ADDRESS = 5'b00000;
wire booleanA, booleanB, booleanC, booleanD, booleanE;
assign booleanA = regWriteMem == 1'b1 && MemRegisterRd == EXRs1 && MemRegisterRd != ZERO_ADDRESS;
assign booleanB = regWriteMem == 1'b1 && MemRegisterRd == EXRs2 && MemRegisterRd != ZERO_ADDRESS;
assign booleanC = regWriteMem == 1'b1 && MemRegisterRd == IDRs1 && MemRegisterRd != ZERO_ADDRESS;
assign booleanD = regWriteMem == 1'b1 && MemRegisterRd == IDRs2 && MemRegisterRd != ZERO_ADDRESS;
assign booleanE = regWriteWB == 1'b1 && MEMRs2 == WBRegisterRd && WBRegisterRd != ZERO_ADDRESS && WB_mem_read;

	// ALU Operand 1
	always @(*) begin
		if (booleanA == 1'b1) begin
			ControlA = 2'b01;
		end else if (regWriteWB == 1'b1 && WBRegisterRd == EXRs1 && WBRegisterRd != ZERO_ADDRESS && booleanA == 1'b0) begin
			ControlA = 2'b10;
		end else begin
			ControlA = 2'b00;
		end
	end

	// ALU Operand 2
	always @(*) begin
		if (booleanB == 1'b1) begin
			ControlB = 2'b01;
		end else if (regWriteWB == 1'b1 && WBRegisterRd == EXRs2 && WBRegisterRd != ZERO_ADDRESS && booleanB == 1'b0) begin
			ControlB = 2'b10;
		end else begin
			ControlB = 2'b00;
		end
	end

	// Operand 1 ID stage
	always @(*) begin
		if (booleanC == 1'b1) begin
			ControlC = 1'b1; // Forward from Mem stage
		end else begin
			ControlC = 1'b0;
		end
	end

	// Operand 2 ID stage
	always @(*) begin
		if (booleanD == 1'b1) begin
			ControlD = 1'b1; // Forward from Mem stage
		end else begin
			ControlD = 1'b0;
		end
	end

	// Forwarding to memory write data
	always @(*) begin
		if (booleanE == 1'b1) begin
			ControlE = 1'b1; // Forward from WB stage
		end else begin
			ControlE = 1'b0;
		end
	end

endmodule

