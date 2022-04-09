module branchPredictionTable #(
	parameter integer N_REG = 16 // Size of branchprediction table
	)(
    input wire clk,
    input wire arst_n,
    input wire [63:0] IF_PC, // PC in IF stage
    input wire [63:0] branchPC, // The branch PC computed in the ID stage
    input wire notFlushed, // ie. correct prediction
    input wire [31:0] ID_INST, // Instruction in the ID stage
    output wire [63:0] predictedBranchPC, // Predicted branch
    output reg branchTaken // If the branch is taken or not
    );

parameter integer N_BITS = $clog2(N_REG);
parameter integer BRANCH_EQ  = 7'b1100011;

integer idx; // Loop index

reg [63:0] BranchPCTable [0:N_REG-1]; // Contains the PC of the branches
reg [1:0] BPT [0:N_REG-1]; // Contains the predictions
reg [0:N_REG-1] validTable; // Contains the valid bits

wire [N_BITS-1:0] BPTReadAddress, BPTWriteAddress;
assign BPTReadAddress = IF_PC[1+N_BITS:2]; // 'address' of instruction in IF stage
assign BPTWriteAddress = BPTReadAddress - 1; // 'address' of instruction in ID stage

// --------- Read procesess --------- (IF Stage)
assign predictedBranchPC = BranchPCTable[BPTReadAddress];

always @(*) begin
    case(BPT[BPTReadAddress])
        2'b00: branchTaken = 1'b0;
        2'b01: branchTaken = 1'b0;
        2'b10: branchTaken = 1'b1 & validTable[BPTReadAddress]; // If unvalid address (eg. at startup): do not take branch
        2'b11: branchTaken = 1'b1 & validTable[BPTReadAddress];
    endcase
end

// --------- Write procesess --------- (ID Stage)

// BranchPCTable write process
always@(posedge clk, negedge arst_n) begin
    if(arst_n == 1'b0)begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin
            BranchPCTable[idx] <= 'b0;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTWriteAddress) begin
                BranchPCTable[idx] <= branchPC;
            end else begin
                BranchPCTable[idx] <= BranchPCTable[idx];
            end
        end
    end
end

// Update valid table
always@(posedge clk, negedge arst_n) begin
    if(arst_n == 1'b0)begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin
            validTable[idx] <= 'b0;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTWriteAddress) begin
                validTable[idx] <= 1'b1;
            end else begin
                validTable[idx] <= validTable[idx];
            end
        end
    end
end


// Update Prediction
always@(posedge clk, negedge arst_n) begin
    if(arst_n == 1'b0)begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin
            BPT[idx] <= 2'b01;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTWriteAddress) begin // Update prediction for specific branch
                if (notFlushed == 1'b1) begin // prediction correct
                    case(BPT[idx])
                        2'b00: BPT[idx] <= 2'b00;
                        2'b01: BPT[idx] <= 2'b00;
                        2'b10: BPT[idx] <= 2'b11;
                        2'b11: BPT[idx] <= 2'b11;
                    endcase
                end else begin
                    case(BPT[idx]) // prediction incorrect
                        2'b00: BPT[idx] <= 2'b01;
                        2'b01: BPT[idx] <= 2'b10;
                        2'b10: BPT[idx] <= 2'b01;
                        2'b11: BPT[idx] <= 2'b10;
                    endcase
                end
            end else begin // Other branches: store old prediction
                BPT[idx] <= BPT[idx];
            end
        end
    end
end

endmodule
