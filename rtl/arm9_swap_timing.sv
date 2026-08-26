module arm9_swap_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic [1:0]                        result_interlock_cycles,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [2:0]                        cycle_number,
  output logic [2:0]                        cycle_total,
  output logic [1:0]                        active_result_interlock_cycles,
  output arm9_timing_pkg::arm9_bus_cycle_e instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e data_cycle_type,
  output logic                              instruction_order_documented,
  output logic                              data_order_documented,
  output logic [2:0]                        instruction_sequential_cycles,
  output logic [2:0]                        instruction_internal_cycles,
  output logic [2:0]                        data_nonsequential_cycles,
  output logic [2:0]                        data_internal_cycles,
  output logic                              swap_read_cycle,
  output logic                              swap_write_cycle,
  output logic                              data_lock,
  output logic                              operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic request_valid;
  logic [1:0] latched_result_interlock_cycles;

  always_comb begin
    request_valid = result_interlock_cycles <= 2'd1;
    if ((PROFILE == ARM9_PROFILE_ARM946ES) &&
        (result_interlock_cycles == 2'd2)) begin
      request_valid = 1'b1;
    end

    ready = !busy;
    cycle_valid = busy;
    active_result_interlock_cycles =
      busy ? latched_result_interlock_cycles : 2'd0;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    data_order_documented = 1'b0;
    instruction_sequential_cycles = 3'd0;
    instruction_internal_cycles = 3'd0;
    data_nonsequential_cycles = 3'd0;
    data_internal_cycles = 3'd0;
    swap_read_cycle = 1'b0;
    swap_write_cycle = 1'b0;
    data_lock = 1'b0;

    if (busy) begin
      instruction_sequential_cycles = 3'd1;
      instruction_internal_cycles = cycle_total - 3'd1;
      data_nonsequential_cycles = 3'd2;
      data_internal_cycles = cycle_total - 3'd2;

      swap_read_cycle = cycle_number == 3'd1;
      swap_write_cycle = cycle_number == 3'd2;
      data_lock = cycle_number <= 3'd2;

      if (PROFILE == ARM9_PROFILE_ARM946ES) begin
        instruction_order_documented = 1'b1;
        data_order_documented = 1'b1;
        instruction_cycle_type =
          (cycle_number == cycle_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                          ARM9_BUS_CYCLE_INTERNAL;
        data_cycle_type =
          (cycle_number <= 3'd2) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
                                   ARM9_BUS_CYCLE_INTERNAL;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 3'd0;
      cycle_total <= 3'd0;
      latched_result_interlock_cycles <= 2'd0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        if (request_valid) begin
          request_accepted <= 1'b1;
          busy <= 1'b1;
          cycle_number <= 3'd1;
          cycle_total <= 3'd2 + {1'b0, result_interlock_cycles};
          latched_result_interlock_cycles <= result_interlock_cycles;
        end else begin
          request_error <= 1'b1;
        end
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
    if (!reset) begin
      assert (!(request_accepted && request_error));
      if (busy) begin
        assert ((cycle_total >= 3'd2) && (cycle_total <= 3'd4));
        assert ((cycle_number >= 3'd1) &&
                (cycle_number <= cycle_total));
        assert (cycle_total ==
                3'd2 + {1'b0, latched_result_interlock_cycles});
        assert (instruction_sequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_nonsequential_cycles + data_internal_cycles ==
                cycle_total);
        assert (!(swap_read_cycle && swap_write_cycle));
        assert (data_lock == (swap_read_cycle || swap_write_cycle));
        if (instruction_order_documented) begin
          assert (PROFILE == ARM9_PROFILE_ARM946ES);
          assert (instruction_cycle_type !=
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (PROFILE == ARM9_PROFILE_ARM9TDMI);
          assert (instruction_cycle_type ==
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end
        if (data_order_documented) begin
          assert (PROFILE == ARM9_PROFILE_ARM946ES);
          assert (data_cycle_type != ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (PROFILE == ARM9_PROFILE_ARM9TDMI);
          assert (data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
        end
      end
      if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
        assert (!busy || (latched_result_interlock_cycles <= 2'd1));
      end
    end
  end
`endif
endmodule
