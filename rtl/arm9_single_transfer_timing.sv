module arm9_single_transfer_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                                       clk,
  input  logic                                       reset,
  input  logic                                       start,
  input  logic                                       load_operation,
  input  logic                                       store_operation,
  input  arm9_timing_pkg::arm9_load_timing_class_e  load_timing_class,
  output logic                                       ready,
  output logic                                       request_accepted,
  output logic                                       request_error,
  output logic                                       busy,
  output logic                                       cycle_valid,
  output logic [2:0]                                 cycle_number,
  output logic [2:0]                                 cycle_total,
  output logic                                       active_load_operation,
  output logic                                       active_store_operation,
  output arm9_timing_pkg::arm9_load_timing_class_e  active_load_timing_class,
  output arm9_timing_pkg::arm9_bus_cycle_e          instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e          data_cycle_type,
  output logic                                       instruction_order_documented,
  output logic                                       data_order_documented,
  output logic [2:0]                                 instruction_sequential_cycles,
  output logic [2:0]                                 instruction_nonsequential_cycles,
  output logic [2:0]                                 instruction_internal_cycles,
  output logic [2:0]                                 data_nonsequential_cycles,
  output logic [2:0]                                 data_internal_cycles,
  output logic                                       operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic request_valid;
  logic [2:0] requested_cycles;
  logic latched_load_operation;
  logic latched_store_operation;
  arm9_load_timing_class_e latched_load_timing_class;

  always_comb begin
    request_valid = load_operation ^ store_operation;
    if (store_operation &&
        (load_timing_class != ARM9_LOAD_TIMING_NORMAL)) begin
      request_valid = 1'b0;
    end

    unique case (load_timing_class)
      ARM9_LOAD_TIMING_NORMAL:           requested_cycles = 3'd1;
      ARM9_LOAD_TIMING_WORD_INTERLOCK:   requested_cycles = 3'd2;
      ARM9_LOAD_TIMING_ROTATE_INTERLOCK: requested_cycles = 3'd3;
      ARM9_LOAD_TIMING_PC_DESTINATION:   requested_cycles = 3'd5;
    endcase

    ready = !busy;
    cycle_valid = busy;
    active_load_operation = busy && latched_load_operation;
    active_store_operation = busy && latched_store_operation;
    active_load_timing_class = latched_load_timing_class;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    data_order_documented = 1'b0;
    instruction_sequential_cycles = 3'd0;
    instruction_nonsequential_cycles = 3'd0;
    instruction_internal_cycles = 3'd0;
    data_nonsequential_cycles = 3'd0;
    data_internal_cycles = 3'd0;
    if (busy) begin
      data_nonsequential_cycles = 3'd1;
      if (latched_store_operation ||
          (latched_load_timing_class == ARM9_LOAD_TIMING_NORMAL)) begin
        instruction_sequential_cycles = 3'd1;
      end else if (latched_load_timing_class ==
                   ARM9_LOAD_TIMING_PC_DESTINATION) begin
        instruction_sequential_cycles = 3'd2;
        instruction_nonsequential_cycles = 3'd1;
        instruction_internal_cycles = 3'd2;
        data_internal_cycles = 3'd4;
      end else begin
        instruction_sequential_cycles = 3'd1;
        instruction_internal_cycles = cycle_total - 3'd1;
        data_internal_cycles = cycle_total - 3'd1;
      end

      if ((PROFILE == ARM9_PROFILE_ARM946ES) ||
          (cycle_total == 3'd1)) begin
        instruction_order_documented = 1'b1;
        data_order_documented = 1'b1;

        if (cycle_total == 3'd1) begin
          instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
        end else if (latched_load_timing_class ==
                     ARM9_LOAD_TIMING_PC_DESTINATION) begin
          if (cycle_number <= 3'd2) begin
            instruction_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
          end else if (cycle_number == 3'd3) begin
            instruction_cycle_type = ARM9_BUS_CYCLE_NONSEQUENTIAL;
          end else begin
            instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
          end
        end else begin
          instruction_cycle_type =
            (cycle_number == cycle_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                            ARM9_BUS_CYCLE_INTERNAL;
        end

        data_cycle_type =
          (cycle_number == 3'd1) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
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
      latched_load_operation <= 1'b0;
      latched_store_operation <= 1'b0;
      latched_load_timing_class <= ARM9_LOAD_TIMING_NORMAL;
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
          cycle_total <= requested_cycles;
          latched_load_operation <= load_operation;
          latched_store_operation <= store_operation;
          latched_load_timing_class <= load_timing_class;
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
      assert (!(latched_load_operation && latched_store_operation));
      if (busy) begin
        assert ((cycle_total == 3'd1) || (cycle_total == 3'd2) ||
                (cycle_total == 3'd3) || (cycle_total == 3'd5));
        assert ((cycle_number >= 3'd1) &&
                (cycle_number <= cycle_total));
        assert (instruction_sequential_cycles +
                instruction_nonsequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_nonsequential_cycles + data_internal_cycles ==
                cycle_total);
        if (instruction_order_documented) begin
          assert (instruction_cycle_type !=
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (instruction_cycle_type ==
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end
        if (data_order_documented) begin
          assert (data_cycle_type != ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
        end
      end
    end
  end
`endif
endmodule
