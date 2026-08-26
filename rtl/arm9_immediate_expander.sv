module arm9_immediate_expander (
  input  logic [7:0]  immediate_value,
  input  logic [3:0]  rotate_imm,
  input  logic        carry_in,
  output logic [31:0] expanded_value,
  output logic        carry_out
);
  logic [4:0] rotation;
  logic [31:0] unrotated_value;

  always_comb begin
    rotation       = {rotate_imm, 1'b0};
    unrotated_value = {24'b0, immediate_value};

    if (rotation == 0) begin
      expanded_value = unrotated_value;
      carry_out       = carry_in;
    end else begin
      expanded_value = (unrotated_value >> rotation) |
                       (unrotated_value << (32 - rotation));
      carry_out       = expanded_value[31];
    end
  end
endmodule
