// Alu that can only add integers. Used in issue 2 (addi instruction pipeline)
module imm_alu #(
   parameter integer DATA_W = 64
   )(
        input   wire signed [DATA_W-1:0] alu_in_0,
        input   wire signed [DATA_W-1:0] alu_in_1,
        output  reg  signed [DATA_W-1:0] alu_out
   );

    always @(*) begin
        alu_out = alu_in_0 + alu_in_1;
    end

endmodule