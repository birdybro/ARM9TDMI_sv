module arm9_psr_transfer_decoder (
  input  logic [31:0] instruction,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic [3:0]  condition,
  output logic        mrs_operation,
  output logic        msr_operation,
  output logic        immediate_operand,
  output logic        spsr_select,
  output logic [3:0]  field_mask,
  output logic [3:0]  destination_register,
  output logic [3:0]  source_register,
  output logic [3:0]  rotate_imm,
  output logic [7:0]  immediate_value
);
  logic mrs_match;
  logic msr_register_match;
  logic msr_immediate_match;

  always_comb begin
    condition = instruction[31:28];
    spsr_select = instruction[22];
    field_mask = instruction[19:16];
    destination_register = instruction[15:12];
    source_register = instruction[3:0];
    rotate_imm = instruction[11:8];
    immediate_value = instruction[7:0];

    mrs_match = (condition != 4'b1111) &&
                (instruction[27:23] == 5'b00010) &&
                (instruction[21:20] == 2'b00) &&
                (instruction[19:16] == 4'b1111) &&
                (instruction[11:0] == 12'b0);
    msr_register_match = (condition != 4'b1111) &&
                         (instruction[27:23] == 5'b00010) &&
                         (instruction[21:20] == 2'b10) &&
                         (instruction[15:4] == 12'hf00);
    msr_immediate_match = (condition != 4'b1111) &&
                          (instruction[27:23] == 5'b00110) &&
                          (instruction[21:20] == 2'b10) &&
                          (instruction[15:12] == 4'hf);

    decode_match = mrs_match || msr_register_match ||
                   msr_immediate_match;
    mrs_operation = mrs_match;
    msr_operation = msr_register_match || msr_immediate_match;
    immediate_operand = msr_immediate_match;
    unpredictable_encoding = mrs_match &&
                             (destination_register == 4'hf);
    encoding_valid = decode_match && !unpredictable_encoding;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(mrs_operation && msr_operation));
    assert (!(mrs_operation && immediate_operand));
    assert (!immediate_operand || msr_operation);
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    if (mrs_operation) begin
      assert (field_mask == 4'hf);
      assert (instruction[11:0] == 12'b0);
    end
    if (msr_operation && !immediate_operand) begin
      assert (instruction[15:4] == 12'hf00);
    end
    if (immediate_operand) begin
      assert (instruction[15:12] == 4'hf);
    end
  end
`endif
endmodule
