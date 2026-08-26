module arm9_pipeline_refill_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              branch_operation,
  input  logic                              exception_entry,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [1:0]                        cycle_number,
  output logic                              active_branch_operation,
  output logic                              active_exception_entry,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic [1:0]                        instruction_sequential_cycles,
  output logic [1:0]                        instruction_nonsequential_cycles,
  output logic [1:0]                        data_internal_cycles,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic request_valid;
  logic latched_branch_operation;
  logic latched_exception_entry;

  always_comb begin
    request_valid = branch_operation ^ exception_entry;
    ready = !busy;
    cycle_valid = busy;
    active_branch_operation = busy && latched_branch_operation;
    active_exception_entry = busy && latched_exception_entry;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    instruction_sequential_cycles = 2'd0;
    instruction_nonsequential_cycles = 2'd0;
    data_internal_cycles = 2'd0;
    if (busy) begin
      instruction_sequential_cycles = 2'd2;
      instruction_nonsequential_cycles = 2'd1;
      data_internal_cycles = 2'd3;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;

      // DDI0165B Tables 8-4, 8-6, and 8-27 explicitly show N,S,S.
      // DDI0180A Table 7-2 supplies only the 1N+2S aggregate.
      if (PROFILE == ARM9_PROFILE_ARM946ES) begin
        instruction_order_documented = 1'b1;
        instruction_cycle_type =
          (cycle_number == 2'd1) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
                                   ARM9_BUS_CYCLE_SEQUENTIAL;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 2'd0;
      latched_branch_operation <= 1'b0;
      latched_exception_entry <= 1'b0;
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
          latched_branch_operation <= branch_operation;
          latched_exception_entry <= exception_entry;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        if (cycle_number == 2'd3) begin
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
      assert (!(latched_branch_operation && latched_exception_entry));
      if (busy) begin
        assert (cycle_number != 2'd0);
        assert (instruction_sequential_cycles +
                instruction_nonsequential_cycles == 2'd3);
        assert (data_internal_cycles == 2'd3);
        assert (data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
        if (instruction_order_documented) begin
          assert (PROFILE == ARM9_PROFILE_ARM946ES);
          assert (instruction_cycle_type !=
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (PROFILE == ARM9_PROFILE_ARM9TDMI);
          assert (instruction_cycle_type ==
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end
      end
    end
  end
`endif
endmodule
