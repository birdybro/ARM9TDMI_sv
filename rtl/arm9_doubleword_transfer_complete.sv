module arm9_doubleword_transfer_complete (
  input  logic        completion_valid,
  input  logic        precise_data_abort,
  input  logic        transfer_load,
  input  logic [3:0]  first_data_register,
  input  logic [3:0]  second_data_register,
  input  logic [31:0] first_load_value,
  input  logic [31:0] second_load_value,
  input  logic        base_writeback_pending,
  input  logic [3:0]  base_register,
  input  logic [31:0] base_writeback_value,
  output logic        data_abort_taken,
  output logic        destination_values_unpredictable_on_abort,
  output logic        first_destination_write_valid,
  output logic [3:0]  first_destination_write_register,
  output logic [31:0] first_destination_write_value,
  output logic        second_destination_write_valid,
  output logic [3:0]  second_destination_write_register,
  output logic [31:0] second_destination_write_value,
  output logic        base_writeback_valid,
  output logic [3:0]  base_writeback_register,
  output logic [31:0] committed_base_writeback_value,
  output logic        base_restored_on_abort
);
  logic successful_completion;

  always_comb begin
    data_abort_taken = completion_valid && precise_data_abort;
    successful_completion = completion_valid && !precise_data_abort;
    destination_values_unpredictable_on_abort = data_abort_taken &&
                                                transfer_load;

    first_destination_write_valid = successful_completion && transfer_load;
    first_destination_write_register = first_data_register;
    first_destination_write_value = first_load_value;
    second_destination_write_valid = successful_completion && transfer_load;
    second_destination_write_register = second_data_register;
    second_destination_write_value = second_load_value;

    base_writeback_valid = successful_completion &&
                           base_writeback_pending;
    base_writeback_register = base_register;
    committed_base_writeback_value = base_writeback_value;
    base_restored_on_abort = data_abort_taken && base_writeback_pending;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (first_destination_write_valid ==
            second_destination_write_valid);
    assert (!(data_abort_taken &&
              (first_destination_write_valid ||
               second_destination_write_valid || base_writeback_valid)));
    assert (!(destination_values_unpredictable_on_abort &&
              (!data_abort_taken || !transfer_load)));
    assert (!(first_destination_write_valid &&
              (!completion_valid || precise_data_abort || !transfer_load)));
    assert (!(base_writeback_valid &&
              (!completion_valid || precise_data_abort ||
               !base_writeback_pending)));
    assert (!(base_restored_on_abort &&
              (!data_abort_taken || !base_writeback_pending)));
    if (completion_valid) begin
      assert (!first_data_register[0]);
      assert (first_data_register < 4'he);
      assert (second_data_register == first_data_register + 4'd1);
    end
  end
`endif
endmodule
