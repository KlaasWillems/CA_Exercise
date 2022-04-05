//Files: pc.v
//Function: This block has 2 functions (1) Increase the current pc by 4 (2) Update the value of the current pc with the following pc ( I.e pc+4) or with the pc obtained from a control instruction (BEQ or JUMP). The zero flag from the ALU is used to make this decision.
//Inputs:
//clk: System clock
//arst_n: Asynchronous Reset
//enable: External signal that enables the updating of the pc when it is asserted. 
//branch_pc: Address of the branch target previously processed.
//Jump_pc: Address of the jump target previously processed.
//Zero_flag: Output of the ALU that informs if the result of the last operation is 0. This is used for processing the BEQ instructions where a subtraction between 2 operands allows to check if the condition is met.
//Branch: Signal generated by the control unit if a branch instruction is being processed.
//Jump: Signal generated by the control unit if a jump instruction is being processed.
//Outputs:
//updated_pc: Next PC used for the next clock cycle. 
//current_pc: PC that is currently processed. 


module pc#(
   parameter integer DATA_W = 16
   )(
      input wire              clk,
      input wire              arst_n,
      input wire              enable,
      input wire [DATA_W-1:0] branch_pc,
      input wire [DATA_W-1:0] jump_pc,  
      input wire              zero_flag,
      input wire              branch,
      input wire              jump,
      input wire              branchTaken,
      input wire [DATA_W-1:0] predictionPC,
      input wire [6:0]       IF_INST_OPCODE, 
      output reg  [DATA_W-1:0] updated_pc,
      output reg  [DATA_W-1:0] current_pc
   );

   localparam  [DATA_W-1:0] PC_INCREASE= {{(DATA_W-3){1'b0}},3'd4};
   parameter integer BRANCH = 7'b1100011;
   
   wire prediction_pc_src;
   wire [DATA_W-1:0] pc_r, next_pc, next_pc_i, next_pc_i1;
   reg               pc_src;
 

   assign prediction_pc_src = branchTaken && IF_INST_OPCODE == BRANCH; 
   always@(*) pc_src = zero_flag & branch; 
      
   mux_2#(
      .DATA_W(DATA_W)
   ) mux_prediction( 
      .input_a (predictionPC),
      .input_b (updated_pc),
      .select_a(prediction_pc_src),
      .mux_out (next_pc_i1)
   );

   mux_2#(
      .DATA_W(DATA_W)
   ) mux_branch( 
      .input_a (branch_pc ),
      .input_b (next_pc_i1),
      .select_a(pc_src    ),
      .mux_out (next_pc_i )
   );
   
   mux_2#(
      .DATA_W(DATA_W)
   ) mux_jump( 
      .input_a (jump_pc   ),
      .input_b (next_pc_i ),
      .select_a(jump      ),
      .mux_out (next_pc   )
   );

   reg_arstn_en#(
      .DATA_W(DATA_W),
      .PRESET_VAL('b0)
   ) pc_register(
      .clk   (clk       ),
      .arst_n(arst_n    ),
      .din   (next_pc   ),
      .en    (enable    ),
      .dout  (current_pc)
   );
   
   always@(*) updated_pc = current_pc+PC_INCREASE;

endmodule


