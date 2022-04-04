module branchPredictionTable(
    input wire clk,
    input wire arst_n,
    input wire [63:0] IF_PC,
    input wire [63:0] branchPC,
    input wire zero_flag, // rs1 == rs2
    input wire [31:0] ID_INST,
    output wire [63:0] predictedBranchPC,
    output reg branchTaken
    );

parameter integer N_REG = 4;
parameter integer N_BITS = $clog2(N_REG);
parameter integer BRANCH_EQ  = 7'b1100011;

integer idx;

reg [63:0] BranchPCTable [0:N_REG-1]; // Contains the PC of the branches
reg [1:0] BPT [0:N_REG-1]; // Contains the predictions
reg [0:N_REG-1] validTable; // Contains the valid bits

wire [N_BITS-1:0] BPTAddress;
assign BPTAddress = IF_PC[2*N_BITS-1:N_BITS];

// output procesess
assign predictedBranchPC = BranchPCTable[BPTAddress];

always @(*) begin
    case(BPT[BPTAddress])
        2'b00: branchTaken = 1'b0;
        2'b01: branchTaken = 1'b0;
        2'b10: branchTaken = 1'b1 & validTable[BPTAddress]; // If unvalid address (eg. at startup): do not take branch
        2'b11: branchTaken = 1'b1 & validTable[BPTAddress];
    endcase
end

// BranchPCTable write process
always@(posedge clk, negedge arst_n) begin
    if(arst_n == 1'b0)begin
        for(idx = 0; idx < N_REG; idx = idx+1)begin
            BranchPCTable[idx] <= 'b0;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTAddress) begin
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
        for(idx = 0; idx < N_REG; idx = idx+1)begin
            validTable[idx] <= 'b0;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTAddress) begin
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
        for(idx = 0; idx < N_REG; idx = idx+1)begin
            BPT[idx] <= 'b0;
        end
    end else begin
        for(idx = 0; idx < N_REG; idx = idx+1) begin  
            if (ID_INST[6:0] == BRANCH_EQ && idx == BPTAddress) begin // Update prediction for specific branch
                if (zero_flag == 1'b1) begin
                    case(BPT[idx])
                        2'b00: BPT[idx] <= 2'b01;
                        2'b01: BPT[idx] <= 2'b10;
                        2'b10: BPT[idx] <= 2'b11;
                        2'b11: BPT[idx] <= 2'b11;
                    endcase
                end else begin
                    case(BPT[idx])
                        2'b00: BPT[idx] <= 2'b00;
                        2'b01: BPT[idx] <= 2'b00;
                        2'b10: BPT[idx] <= 2'b01;
                        2'b11: BPT[idx] <= 2'b10;
                    endcase
                end
            end else begin // Other branch store old prediction
                BPT[idx] <= BPT[idx];
            end
        end
    end
end

endmodule
