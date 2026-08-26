module arm9_misc_transfer_complete (
  input  logic                                  completion_valid,
  input  logic                                  precise_data_abort,
  input  arm9_isa_pkg::arm9_misc_transfer_kind_e transfer_kind,
  input  logic [3:0]                            data_register,
  input  logic [7:0]                            selected_byte_value,
  input  logic [15:0]                           selected_halfword_value,
  input  logic                                  base_writeback_pending,
  input  logic [3:0]                            base_register,
  input  logic [31:0]                           base_writeback_value,
  output logic                                  data_abort_taken,
  output logic                                  destination_write_valid,
  output logic [3:0]                            destination_write_register,
  output logic [31:0]                           destination_write_value,
  output logic                                  base_writeback_valid,
  output logic [3:0]                            base_writeback_register,
  output logic [31:0]                           committed_base_writeback_value,
  output logic                                  base_restored_on_abort
);
  import arm9_isa_pkg::*;

  logic load_format_valid;
  logic [31:0] formatted_load_value;
  logic successful_completion;

  arm9_misc_load_data_format load_formatter (
    .transfer_kind,
    .selected_byte_value,
    .selected_halfword_value,
    .format_valid(load_format_valid),
    .load_value(formatted_load_value)
  );

  always_comb begin
    data_abort_taken = completion_valid && precise_data_abort;
    successful_completion = completion_valid && !precise_data_abort;

    destination_write_valid = successful_completion && load_format_valid;
    destination_write_register = data_register;
    destination_write_value = formatted_load_value;

    base_writeback_valid = successful_completion &&
                           base_writeback_pending;
    base_writeback_register = base_register;
    committed_base_writeback_value = base_writeback_value;
    base_restored_on_abort = data_abort_taken && base_writeback_pending;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(data_abort_taken &&
              (destination_write_valid || base_writeback_valid)));
    assert (!(destination_write_valid &&
              (!completion_valid || precise_data_abort ||
               !load_format_valid)));
    assert (!(base_writeback_valid &&
              (!completion_valid || precise_data_abort ||
               !base_writeback_pending)));
    assert (!(base_restored_on_abort &&
              (!data_abort_taken || !base_writeback_pending)));
    if (completion_valid) begin
      assert (data_register != 4'hf);
    end
  end
`endif
endmodule
