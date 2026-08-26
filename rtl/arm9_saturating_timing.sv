module arm9_saturating_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM946ES
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              result_interlock,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [1:0]                        cycle_number,
  output logic [1:0]                        cycle_total,
  output logic                              active_result_interlock,
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

  logic latched_result_interlock;

  always_comb begin
    ready = !busy;
    cycle_valid = busy;
    active_result_interlock = busy && latched_result_interlock;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    instruction_sequential_cycles = 2'd0;
    instruction_internal_cycles = 2'd0;
    data_internal_cycles = 2'd0;
    if (busy) begin
      instruction_cycle_type =
        (cycle_number == cycle_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                        ARM9_BUS_CYCLE_INTERNAL;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
      instruction_order_documented = 1'b1;
      instruction_sequential_cycles = 2'd1;
      instruction_internal_cycles = latched_result_interlock ? 2'd1 : 2'd0;
      data_internal_cycles = cycle_total;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 2'd0;
      cycle_total <= 2'd0;
      latched_result_interlock <= 1'b0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        if (PROFILE == ARM9_PROFILE_ARM946ES) begin
          request_accepted <= 1'b1;
          busy <= 1'b1;
          cycle_number <= 2'd1;
          cycle_total <= result_interlock ? 2'd2 : 2'd1;
          latched_result_interlock <= result_interlock;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        if (cycle_number == cycle_total) begin
          busy <= 1'b0;
          cycle_number <= 2'd0;
          cycle_total <= 2'd0;
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
      if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
        assert (!request_accepted && !busy && !cycle_valid);
      end
      if (busy) begin
        assert (PROFILE == ARM9_PROFILE_ARM946ES);
        assert ((cycle_total == 2'd1) || (cycle_total == 2'd2));
        assert ((cycle_number >= 2'd1) &&
                (cycle_number <= cycle_total));
        assert (cycle_total ==
                (latched_result_interlock ? 2'd2 : 2'd1));
        assert (instruction_sequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_internal_cycles == cycle_total);
        assert (instruction_order_documented);
      end
    end
  end
`endif
endmodule
