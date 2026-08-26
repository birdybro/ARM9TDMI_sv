module arm9_pld_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM946ES
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic [31:0]                       prefetch_address,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [1:0]                        cycle_number,
  output logic [1:0]                        cycle_total,
  output logic [31:0]                       active_prefetch_address,
  output logic                              data_address_valid,
  output logic                              data_speculative,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic                              data_order_documented,
  output logic [1:0]                        instruction_sequential_cycles,
  output logic [1:0]                        data_internal_cycles,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic [31:0] latched_prefetch_address;

  always_comb begin
    ready = !busy;
    cycle_valid = busy;
    active_prefetch_address = busy ? latched_prefetch_address : 32'b0;
    data_address_valid = busy;
    data_speculative = busy;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    data_order_documented = 1'b0;
    instruction_sequential_cycles = 2'd0;
    data_internal_cycles = 2'd0;
    if (busy) begin
      instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
      instruction_order_documented = 1'b1;
      data_order_documented = 1'b1;
      instruction_sequential_cycles = 2'd1;
      data_internal_cycles = 2'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 2'd0;
      cycle_total <= 2'd0;
      latched_prefetch_address <= 32'b0;
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
          cycle_total <= 2'd1;
          latched_prefetch_address <= prefetch_address;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        busy <= 1'b0;
        cycle_number <= 2'd0;
        cycle_total <= 2'd0;
        operation_complete <= 1'b1;
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
        assert ((cycle_number == 2'd1) && (cycle_total == 2'd1));
        assert (instruction_cycle_type == ARM9_BUS_CYCLE_SEQUENTIAL);
        assert (data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
        assert (instruction_order_documented && data_order_documented);
        assert ((instruction_sequential_cycles == 2'd1) &&
                (data_internal_cycles == 2'd1));
        assert (data_address_valid && data_speculative);
      end
    end
  end
`endif
endmodule
