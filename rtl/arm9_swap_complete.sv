module arm9_swap_complete (
  input  logic        read_access_complete,
  input  logic        read_data_abort,
  input  logic        write_access_complete,
  input  logic        write_data_abort,
  input  logic        byte_swap,
  input  logic [1:0]  original_address_low,
  input  logic [31:0] aligned_read_word,
  input  logic [7:0]  selected_read_byte,
  input  logic [3:0]  destination_register,
  output logic        store_access_permitted,
  output logic        store_access_canceled_on_read_abort,
  output logic        sequence_complete,
  output logic        data_abort_taken,
  output logic        loaded_word_rotation_applied,
  output logic        destination_write_valid,
  output logic [3:0]  destination_write_register,
  output logic [31:0] destination_write_value
);
  logic [31:0] formatted_read_value;
  arm9_load_data_align load_formatter (
    .byte_transfer(byte_swap),
    .address_low(original_address_low),
    .aligned_word_value(aligned_read_word),
    .selected_byte_value(selected_read_byte),
    .load_value(formatted_read_value),
    .unaligned_word_rotation(loaded_word_rotation_applied)
  );

  always_comb begin
    store_access_permitted = read_access_complete && !read_data_abort;
    store_access_canceled_on_read_abort = read_access_complete &&
                                          read_data_abort;

    sequence_complete = store_access_canceled_on_read_abort ||
                        (write_access_complete && store_access_permitted);
    data_abort_taken = store_access_canceled_on_read_abort ||
                       (write_access_complete && write_data_abort &&
                        store_access_permitted);

    destination_write_valid = write_access_complete && !write_data_abort &&
                              store_access_permitted;
    destination_write_register = destination_register;
    destination_write_value = formatted_read_value;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!read_data_abort || read_access_complete);
    assert (!write_access_complete || store_access_permitted);
    assert (!write_data_abort || write_access_complete);
    assert (!(store_access_permitted &&
              store_access_canceled_on_read_abort));
    assert (!(data_abort_taken && destination_write_valid));
    assert (!destination_write_valid || sequence_complete);
    assert (!destination_write_valid ||
            (read_access_complete && !read_data_abort));
    assert (loaded_word_rotation_applied ==
            (!byte_swap && (original_address_low != 2'b00)));
    if (read_access_complete || write_access_complete) begin
      assert (destination_register != 4'hf);
    end
  end
`endif
endmodule
