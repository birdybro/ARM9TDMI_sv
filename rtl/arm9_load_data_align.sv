module arm9_load_data_align (
  input  logic        byte_transfer,
  input  logic [1:0]  address_low,
  input  logic [31:0] aligned_word_value,
  input  logic [7:0]  selected_byte_value,
  output logic [31:0] load_value,
  output logic        unaligned_word_rotation
);
  always_comb begin
    unaligned_word_rotation = !byte_transfer && (address_low != 2'b00);

    if (byte_transfer) begin
      load_value = {24'b0, selected_byte_value};
    end else begin
      case (address_low)
        2'b00: load_value = aligned_word_value;
        2'b01: load_value = {aligned_word_value[7:0],
                             aligned_word_value[31:8]};
        2'b10: load_value = {aligned_word_value[15:0],
                             aligned_word_value[31:16]};
        2'b11: load_value = {aligned_word_value[23:0],
                             aligned_word_value[31:24]};
        default: load_value = 'x;
      endcase
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (unaligned_word_rotation ==
            (!byte_transfer && (address_low != 2'b00)));
    if (byte_transfer) begin
      assert (load_value == {24'b0, selected_byte_value});
    end
  end
`endif
endmodule
