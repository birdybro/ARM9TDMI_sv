module arm9_data_alu (
  input  arm9_isa_pkg::arm9_data_opcode_e opcode,
  input  logic [31:0]                     first_operand,
  input  logic [31:0]                     shifter_operand,
  input  logic                            carry_in,
  input  logic                            overflow_in,
  input  logic                            shifter_carry_out,
  output logic [31:0]                     result,
  output logic                            writes_result,
  output logic                            negative_out,
  output logic                            zero_out,
  output logic                            carry_out,
  output logic                            overflow_out
);
  import arm9_isa_pkg::*;

  logic [32:0] arithmetic_result;

  always_comb begin
    result            = '0;
    writes_result     = 1'b1;
    negative_out      = 1'b0;
    zero_out          = 1'b0;
    carry_out         = shifter_carry_out;
    overflow_out      = overflow_in;
    arithmetic_result = '0;

    case (opcode)
      ARM9_DATA_AND: result = first_operand & shifter_operand;
      ARM9_DATA_EOR: result = first_operand ^ shifter_operand;
      ARM9_DATA_SUB,
      ARM9_DATA_CMP: begin
        arithmetic_result = {1'b0, first_operand} +
                            {1'b0, ~shifter_operand} + 33'd1;
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = (first_operand[31] ^ shifter_operand[31]) &
                       (result[31] ^ first_operand[31]);
      end
      ARM9_DATA_RSB: begin
        arithmetic_result = {1'b0, shifter_operand} +
                            {1'b0, ~first_operand} + 33'd1;
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = (shifter_operand[31] ^ first_operand[31]) &
                       (result[31] ^ shifter_operand[31]);
      end
      ARM9_DATA_ADD,
      ARM9_DATA_CMN: begin
        arithmetic_result = {1'b0, first_operand} +
                            {1'b0, shifter_operand};
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = ~(first_operand[31] ^ shifter_operand[31]) &
                       (result[31] ^ first_operand[31]);
      end
      ARM9_DATA_ADC: begin
        arithmetic_result = {1'b0, first_operand} +
                            {1'b0, shifter_operand} +
                            {{32{1'b0}}, carry_in};
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = ~(first_operand[31] ^ shifter_operand[31]) &
                       (result[31] ^ first_operand[31]);
      end
      ARM9_DATA_SBC: begin
        arithmetic_result = {1'b0, first_operand} +
                            {1'b0, ~shifter_operand} +
                            {{32{1'b0}}, carry_in};
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = (first_operand[31] ^ shifter_operand[31]) &
                       (result[31] ^ first_operand[31]);
      end
      ARM9_DATA_RSC: begin
        arithmetic_result = {1'b0, shifter_operand} +
                            {1'b0, ~first_operand} +
                            {{32{1'b0}}, carry_in};
        result       = arithmetic_result[31:0];
        carry_out    = arithmetic_result[32];
        overflow_out = (shifter_operand[31] ^ first_operand[31]) &
                       (result[31] ^ shifter_operand[31]);
      end
      ARM9_DATA_TST: begin
        result        = first_operand & shifter_operand;
        writes_result = 1'b0;
      end
      ARM9_DATA_TEQ: begin
        result        = first_operand ^ shifter_operand;
        writes_result = 1'b0;
      end
      ARM9_DATA_ORR: result = first_operand | shifter_operand;
      ARM9_DATA_MOV: result = shifter_operand;
      ARM9_DATA_BIC: result = first_operand & ~shifter_operand;
      ARM9_DATA_MVN: result = ~shifter_operand;
      default: begin
        result        = 'x;
        writes_result = 1'bx;
        carry_out     = 1'bx;
        overflow_out  = 1'bx;
      end
    endcase

    if ((opcode == ARM9_DATA_TST) || (opcode == ARM9_DATA_TEQ) ||
        (opcode == ARM9_DATA_CMP) || (opcode == ARM9_DATA_CMN)) begin
      writes_result = 1'b0;
    end

    negative_out = result[31];
    zero_out     = (result == 32'b0);
  end
endmodule
