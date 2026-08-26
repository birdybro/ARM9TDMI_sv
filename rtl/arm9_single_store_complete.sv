module arm9_single_store_complete (
  input  logic        completion_valid,
  input  logic        precise_data_abort,
  input  logic        base_writeback_pending,
  input  logic [3:0]  base_register,
  input  logic [31:0] base_writeback_value,
  output logic        data_abort_taken,
  output logic        base_writeback_valid,
  output logic [3:0]  base_writeback_register,
  output logic [31:0] committed_base_writeback_value,
  output logic        base_restored_on_abort
);
  always_comb begin
    data_abort_taken = completion_valid && precise_data_abort;
    base_writeback_valid = completion_valid && !precise_data_abort &&
                           base_writeback_pending;
    base_writeback_register = base_register;
    committed_base_writeback_value = base_writeback_value;
    base_restored_on_abort = data_abort_taken && base_writeback_pending;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(data_abort_taken && base_writeback_valid));
    assert (!(base_writeback_valid &&
              (!completion_valid || precise_data_abort ||
               !base_writeback_pending)));
    assert (!(base_restored_on_abort &&
              (!data_abort_taken || !base_writeback_pending)));
  end
`endif
endmodule
