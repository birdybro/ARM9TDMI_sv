module arm9_single_load_complete #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic        completion_valid,
  input  logic        data_abort,
  input  logic [3:0]  data_register,
  input  logic [31:0] load_value,
  input  logic        base_writeback_pending,
  input  logic [3:0]  base_register,
  input  logic [31:0] base_writeback_value,
  input  logic        arm946_disable_loading_tbit,
  output logic        data_abort_taken,
  output logic        destination_write_valid,
  output logic [3:0]  destination_write_register,
  output logic [31:0] destination_write_value,
  output logic        base_writeback_valid,
  output logic [3:0]  base_writeback_register,
  output logic [31:0] committed_base_writeback_value,
  output logic        base_restored_on_abort,
  output logic        pc_destination,
  output logic        pc_write_valid,
  output logic [31:0] pc_write_value,
  output logic        pc_write_thumb_state,
  output logic        pc_load_tbit_enabled,
  output logic        unpredictable_result
);
  import arm9_profile_pkg::*;

  logic successful_completion;

  always_comb begin
    pc_destination = data_register == 4'hf;
    data_abort_taken = completion_valid && data_abort;
    successful_completion = completion_valid && !data_abort;
    pc_load_tbit_enabled = (PROFILE == ARM9_PROFILE_ARM946ES) &&
                           !arm946_disable_loading_tbit;

    unpredictable_result = successful_completion && pc_destination &&
                           pc_load_tbit_enabled &&
                           (load_value[1:0] == 2'b10);

    destination_write_valid = successful_completion && !pc_destination &&
                              !unpredictable_result;
    destination_write_register = data_register;
    destination_write_value = load_value;

    base_writeback_valid = successful_completion &&
                           base_writeback_pending &&
                           !unpredictable_result;
    base_writeback_register = base_register;
    committed_base_writeback_value = base_writeback_value;
    base_restored_on_abort = data_abort_taken && base_writeback_pending;

    pc_write_valid = successful_completion && pc_destination &&
                     !unpredictable_result;
    if (pc_load_tbit_enabled) begin
      pc_write_value = {load_value[31:1], 1'b0};
      pc_write_thumb_state = load_value[0];
    end else begin
      pc_write_value = {load_value[31:2], 2'b00};
      pc_write_thumb_state = 1'b0;
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(data_abort_taken &&
              (destination_write_valid || base_writeback_valid ||
               pc_write_valid)));
    assert (!(destination_write_valid && pc_destination));
    assert (!(pc_write_valid && !pc_destination));
    assert (!(unpredictable_result &&
              (destination_write_valid || base_writeback_valid ||
               pc_write_valid)));
    assert (!(base_restored_on_abort &&
              (!data_abort_taken || !base_writeback_pending)));

    if (pc_load_tbit_enabled) begin
      assert (PROFILE == ARM9_PROFILE_ARM946ES);
      assert (pc_write_value[0] == 1'b0);
    end else begin
      assert (pc_write_value[1:0] == 2'b00);
      assert (!pc_write_thumb_state);
    end
  end
`endif
endmodule
