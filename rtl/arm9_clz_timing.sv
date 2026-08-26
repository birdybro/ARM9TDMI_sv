module arm9_clz_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM946ES
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [2:0]                        cycle_number,
  output logic [2:0]                        cycle_total,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic [2:0]                        instruction_sequential_cycles,
  output logic [2:0]                        instruction_nonsequential_cycles,
  output logic [2:0]                        instruction_internal_cycles,
  output logic [2:0]                        data_internal_cycles,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;

  logic core_start;
  logic core_active_register_controlled_shift;
  logic core_active_pc_destination;
  logic unsupported_profile_error;

  assign core_start = start && (PROFILE == ARM9_PROFILE_ARM946ES);
  assign request_error = unsupported_profile_error;

  arm9_data_operation_timing #(
    .PROFILE(PROFILE)
  ) data_operation_timing (
    .clk,
    .reset,
    .start(core_start),
    .register_controlled_shift(1'b0),
    .pc_destination(1'b0),
    .ready,
    .request_accepted,
    .busy,
    .cycle_valid,
    .cycle_number,
    .cycle_total,
    .active_register_controlled_shift(
      core_active_register_controlled_shift
    ),
    .active_pc_destination(core_active_pc_destination),
    .instruction_cycle_type,
    .data_cycle_type,
    .instruction_order_documented,
    .instruction_sequential_cycles,
    .instruction_nonsequential_cycles,
    .instruction_internal_cycles,
    .data_internal_cycles,
    .operation_complete
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      unsupported_profile_error <= 1'b0;
    end else begin
      unsupported_profile_error <=
        start && !busy && (PROFILE == ARM9_PROFILE_ARM9TDMI);
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
        assert (!core_active_register_controlled_shift);
        assert (!core_active_pc_destination);
        assert ((cycle_number == 3'd1) && (cycle_total == 3'd1));
      end
    end
  end
`endif
endmodule
