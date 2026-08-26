module arm9_doubleword_transfer_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM946ES
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              load_double,
  input  logic                              store_double,
  input  logic                              final_word_interlock,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [4:0]                        cycle_number,
  output logic [4:0]                        cycle_total,
  output logic                              active_load_double,
  output logic                              active_store_double,
  output logic                              active_final_word_interlock,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic                              data_order_documented,
  output logic [4:0]                        instruction_sequential_cycles,
  output logic [4:0]                        instruction_nonsequential_cycles,
  output logic [4:0]                        instruction_internal_cycles,
  output logic [4:0]                        data_sequential_cycles,
  output logic [4:0]                        data_nonsequential_cycles,
  output logic [4:0]                        data_internal_cycles,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;

  logic core_start;
  logic core_ready;
  logic core_request_accepted;
  logic core_request_error;
  logic core_busy;
  logic core_cycle_valid;
  logic core_active_load_multiple;
  logic core_active_store_multiple;
  logic [4:0] core_active_register_count;
  logic core_active_load_pc_destination;
  logic core_active_final_word_interlock;
  logic unsupported_profile_error;

  assign core_start = start && (PROFILE == ARM9_PROFILE_ARM946ES);
  assign ready = core_ready;
  assign request_accepted = core_request_accepted;
  assign request_error = core_request_error || unsupported_profile_error;
  assign busy = core_busy;
  assign cycle_valid = core_cycle_valid;
  assign active_load_double = core_active_load_multiple;
  assign active_store_double = core_active_store_multiple;
  assign active_final_word_interlock =
    core_active_final_word_interlock;

  arm9_block_transfer_timing #(
    .PROFILE(PROFILE)
  ) block_timing (
    .clk,
    .reset,
    .start(core_start),
    .load_multiple(load_double),
    .store_multiple(store_double),
    .register_count(5'd2),
    .load_pc_destination(1'b0),
    .final_word_interlock,
    .ready(core_ready),
    .request_accepted(core_request_accepted),
    .request_error(core_request_error),
    .busy(core_busy),
    .cycle_valid(core_cycle_valid),
    .cycle_number,
    .cycle_total,
    .active_load_multiple(core_active_load_multiple),
    .active_store_multiple(core_active_store_multiple),
    .active_register_count(core_active_register_count),
    .active_load_pc_destination(core_active_load_pc_destination),
    .active_final_word_interlock(core_active_final_word_interlock),
    .instruction_cycle_type,
    .data_cycle_type,
    .instruction_order_documented,
    .data_order_documented,
    .instruction_sequential_cycles,
    .instruction_nonsequential_cycles,
    .instruction_internal_cycles,
    .data_sequential_cycles,
    .data_nonsequential_cycles,
    .data_internal_cycles,
    .operation_complete
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      unsupported_profile_error <= 1'b0;
    end else begin
      unsupported_profile_error <=
        start && (PROFILE == ARM9_PROFILE_ARM9TDMI);
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset) begin
      assert (!(request_accepted && request_error));
      if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
        assert (!request_accepted && !busy && !cycle_valid);
      end
      if (busy) begin
        assert (PROFILE == ARM9_PROFILE_ARM946ES);
        assert (core_active_register_count == 5'd2);
        assert (!core_active_load_pc_destination);
        assert (instruction_order_documented);
        assert (data_order_documented);
      end
    end
  end
`endif
endmodule
