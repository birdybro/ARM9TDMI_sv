module arm9_psr_transfer_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              mrs_operation,
  input  logic                              msr_operation,
  input  logic                              msr_flags_only,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [1:0]                        cycle_number,
  output logic [1:0]                        cycle_total,
  output logic                              active_mrs_operation,
  output logic                              active_msr_operation,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic [1:0]                        instruction_sequential_cycles,
  output logic [1:0]                        instruction_internal_cycles,
  output logic [1:0]                        data_internal_cycles,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic       request_valid;
  logic [1:0] requested_cycles;
  logic       latched_mrs_operation;
  logic       latched_msr_operation;

  always_comb begin
    request_valid = mrs_operation ^ msr_operation;
    if (mrs_operation && !msr_operation) begin
      requested_cycles = (PROFILE == ARM9_PROFILE_ARM946ES) ? 2'd2 :
                                                                  2'd1;
    end else if (msr_operation && !mrs_operation) begin
      requested_cycles = msr_flags_only ? 2'd1 : 2'd3;
    end else begin
      requested_cycles = 2'd0;
    end

    ready = !busy;
    cycle_valid = busy;
    active_mrs_operation = busy && latched_mrs_operation;
    active_msr_operation = busy && latched_msr_operation;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    instruction_sequential_cycles = 2'd0;
    instruction_internal_cycles = 2'd0;
    data_internal_cycles = 2'd0;
    if (busy) begin
      instruction_sequential_cycles = 2'd1;
      instruction_internal_cycles = cycle_total - 2'd1;
      data_internal_cycles = cycle_total;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
      if (cycle_total == 2'd1) begin
        instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
        instruction_order_documented = 1'b1;
      end else if (PROFILE == ARM9_PROFILE_ARM946ES) begin
        instruction_cycle_type =
          (cycle_number == cycle_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                          ARM9_BUS_CYCLE_INTERNAL;
        instruction_order_documented = 1'b1;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 2'd0;
      cycle_total <= 2'd0;
      latched_mrs_operation <= 1'b0;
      latched_msr_operation <= 1'b0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        if (request_valid) begin
          request_accepted <= 1'b1;
          busy <= 1'b1;
          cycle_number <= 2'd1;
          cycle_total <= requested_cycles;
          latched_mrs_operation <= mrs_operation;
          latched_msr_operation <= msr_operation;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        if (cycle_number == cycle_total) begin
          busy <= 1'b0;
          cycle_number <= 2'd0;
          operation_complete <= 1'b1;
        end else begin
          cycle_number <= cycle_number + 2'd1;
        end
      end
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset) begin
      assert (!(request_accepted && request_error));
      assert (!(latched_mrs_operation && latched_msr_operation));
      if (busy) begin
        assert (cycle_total != 2'd0);
        assert ((cycle_number >= 2'd1) &&
                (cycle_number <= cycle_total));
        assert (instruction_sequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_internal_cycles == cycle_total);
        assert (data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
        if (instruction_order_documented) begin
          assert (instruction_cycle_type !=
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end
      end
    end
  end
`endif
endmodule
