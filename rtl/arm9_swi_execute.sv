module arm9_swi_execute (
  input  logic [31:0] instruction,
  input  logic [31:0] instruction_address,
  input  logic        negative,
  input  logic        zero,
  input  logic        carry,
  input  logic        overflow,
  output logic        decode_match,
  output logic [3:0]  condition,
  output logic [23:0] comment_field,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        exception_request,
  output logic [31:0] next_instruction_address
);
  logic condition_result;
  logic condition_unconditional;

  arm9_condition_eval condition_evaluator (
    .condition(instruction[31:28]),
    .flag_n(negative),
    .flag_z(zero),
    .flag_c(carry),
    .flag_v(overflow),
    .condition_passed(condition_result),
    .unconditional_space(condition_unconditional)
  );

  always_comb begin
    condition = instruction[31:28];
    comment_field = instruction[23:0];
    decode_match = (condition != 4'b1111) &&
                   (instruction[27:24] == 4'b1111);
    condition_passed = condition_result;
    unconditional_space = condition_unconditional;
    exception_request = decode_match && condition_result;
    next_instruction_address = instruction_address + 32'd4;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(exception_request &&
              (!decode_match || !condition_passed)));
    assert (next_instruction_address == instruction_address + 32'd4);
    if (decode_match) begin
      assert (!unconditional_space);
      assert (instruction[27:24] == 4'b1111);
    end
  end
`endif
endmodule
