

//Branch Unit
//Function: Calculate the next pc in the case of a control instruction (branch or jump).
//Inputs:
//instruction: Instruction currently processed. The least significant bits are used for the calcualting the target pc in the case of a jump instruction. 
//branch_offset: Offset for a branch instruction. 
//updated_pc:  Current PC + 4.
//Outputs: 
//branch_pc: Target PC in the case of a branch instruction.
//jump_pc: Target PC in the case of a jump instruction.

module branch_unit#(
   parameter integer DATA_W     = 16
   )(
      input wire signed [DATA_W-1:0]  updated_pc,
      input wire signed [DATA_W-1:0]  immediate_extended,
      input wire [2:0] func3,
      input wire regEqual,
      input wire branchPrediction,
      output reg signed [DATA_W-1:0]  branch_pc,
      output reg signed [DATA_W-1:0]  jump_pc
   );
   parameter integer BEQ = 3'b000;
   parameter integer BNE = 3'b001;
   localparam  [DATA_W-1:0] PC_INCREASE= {{(DATA_W-3){1'b0}},3'd4};
   reg shouldHaveTaken;

   // Prediction: branch taken but should not have taken: branch_pc = updated_pc
   // Prediction: do not take but should have taken = branch_pc = updated_pc + immediate + pc_increase
   // If the prediction was incorrect we will take branch_pc in the next cycle
   // If the prediction was correct, put the branch pc on the output so that the branch prediction hardware can store it for later
   
   always @(*) begin
      if (func3 == BEQ) begin
         shouldHaveTaken = regEqual;
      end else begin
         shouldHaveTaken = !regEqual;
      end
   end

   always@(*) begin
      if (shouldHaveTaken == 1'b1 && branchPrediction == 1'b0) begin
         branch_pc = updated_pc + immediate_extended - PC_INCREASE; // Take the branch
      end else if (shouldHaveTaken == 1'b0 && branchPrediction == 1'b1) begin // 
         branch_pc = updated_pc; // go back!
      end else begin 
         branch_pc = updated_pc + immediate_extended - PC_INCREASE;
      end
   end
   
   always@(*) jump_pc = updated_pc + immediate_extended - PC_INCREASE;
  
endmodule



