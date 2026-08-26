module arm9_data_operation_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              register_controlled_shift,
  input  logic                              pc_destination,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [2:0]                        cycle_number,
  output logic [2:0]                        cycle_total,
  output logic                              active_register_controlled_shift,
  output logic                              active_pc_destination,
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
  import arm9_timing_pkg::*;

  logic [2:0] requested_cycles;
  logic       latched_register_controlled_shift;
  logic       latched_pc_destination;
  logic [2:0] refill_nonsequential_cycle;

  always_comb begin
    requested_cycles = 3'd1;
    if (register_controlled_shift) begin
      requested_cycles = requested_cycles + 3'd1;
    end
    if (pc_destination) begin
      requested_cycles = requested_cycles + 3'd2;
    end

    ready = !busy;
    cycle_valid = busy;
    active_register_controlled_shift =
      busy && latched_register_controlled_shift;
    active_pc_destination = busy && latched_pc_destination;

    refill_nonsequential_cycle =
      latched_register_controlled_shift ? 3'd2 : 3'd1;
    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    instruction_sequential_cycles = 3'd0;
    instruction_nonsequential_cycles = 3'd0;
    instruction_internal_cycles = 3'd0;
    data_internal_cycles = 3'd0;
    if (busy) begin
      instruction_sequential_cycles =
        latched_pc_destination ? 3'd2 : 3'd1;
      instruction_nonsequential_cycles =
        latched_pc_destination ? 3'd1 : 3'd0;
      instruction_internal_cycles =
        latched_register_controlled_shift ? 3'd1 : 3'd0;
      data_internal_cycles = cycle_total;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;

      // DDI0180A Table 7-2 specifies the aggregate counts but not the
      // chronological order for the multi-cycle ARM9TDMI rows. DDI0165B
      // Table 8-8 specifies the ARM9E-S cycle order explicitly.
      if ((PROFILE == ARM9_PROFILE_ARM946ES) ||
          (cycle_total == 3'd1)) begin
        instruction_order_documented = 1'b1;
        if (latched_register_controlled_shift &&
            (cycle_number == 3'd1)) begin
          instruction_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
        end else if (latched_pc_destination &&
                     (cycle_number == refill_nonsequential_cycle)) begin
          instruction_cycle_type = ARM9_BUS_CYCLE_NONSEQUENTIAL;
        end else begin
          instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 3'd0;
      cycle_total <= 3'd0;
      latched_register_controlled_shift <= 1'b0;
      latched_pc_destination <= 1'b0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        request_accepted <= 1'b1;
        busy <= 1'b1;
        cycle_number <= 3'd1;
        cycle_total <= requested_cycles;
        latched_register_controlled_shift <= register_controlled_shift;
        latched_pc_destination <= pc_destination;
      end else if (busy) begin
        if (cycle_number == cycle_total) begin
          busy <= 1'b0;
          cycle_number <= 3'd0;
          operation_complete <= 1'b1;
        end else begin
          cycle_number <= cycle_number + 3'd1;
        end
      end
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset && busy) begin
      assert ((cycle_total >= 3'd1) && (cycle_total <= 3'd4));
      assert ((cycle_number >= 3'd1) &&
              (cycle_number <= cycle_total));
      assert (instruction_sequential_cycles +
              instruction_nonsequential_cycles +
              instruction_internal_cycles == cycle_total);
      assert (data_internal_cycles == cycle_total);
      assert (data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
      if (instruction_order_documented) begin
        assert (instruction_cycle_type !=
                ARM9_BUS_CYCLE_UNSPECIFIED);
      end else begin
        assert (PROFILE == ARM9_PROFILE_ARM9TDMI);
        assert (cycle_total > 3'd1);
        assert (instruction_cycle_type ==
                ARM9_BUS_CYCLE_UNSPECIFIED);
      end
    end
  end
`endif
endmodule
