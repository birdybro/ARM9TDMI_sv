module arm9_block_transfer_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                              clk,
  input  logic                              reset,
  input  logic                              start,
  input  logic                              load_multiple,
  input  logic                              store_multiple,
  input  logic [4:0]                        register_count,
  input  logic                              load_pc_destination,
  input  logic                              final_word_interlock,
  output logic                              ready,
  output logic                              request_accepted,
  output logic                              request_error,
  output logic                              busy,
  output logic                              cycle_valid,
  output logic [4:0]                        cycle_number,
  output logic [4:0]                        cycle_total,
  output logic                              active_load_multiple,
  output logic                              active_store_multiple,
  output logic [4:0]                        active_register_count,
  output logic                              active_load_pc_destination,
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
  import arm9_timing_pkg::*;

  logic request_valid;
  logic [4:0] requested_cycles;
  logic latched_load_multiple;
  logic latched_store_multiple;
  logic [4:0] latched_register_count;
  logic latched_load_pc_destination;
  logic latched_final_word_interlock;

  always_comb begin
    request_valid = load_multiple ^ store_multiple;
    if ((register_count == 5'd0) || (register_count > 5'd16)) begin
      request_valid = 1'b0;
    end
    if (store_multiple &&
        (load_pc_destination || final_word_interlock)) begin
      request_valid = 1'b0;
    end
    if (load_multiple && final_word_interlock &&
        (load_pc_destination || (register_count <= 5'd1))) begin
      request_valid = 1'b0;
    end

    requested_cycles = register_count;
    if (load_multiple && load_pc_destination) begin
      requested_cycles = register_count + 5'd4;
    end else if (load_multiple && final_word_interlock) begin
      requested_cycles = register_count + 5'd1;
    end else if (register_count == 5'd1) begin
      requested_cycles = 5'd2;
    end

    ready = !busy;
    cycle_valid = busy;
    active_load_multiple = busy && latched_load_multiple;
    active_store_multiple = busy && latched_store_multiple;
    active_register_count = latched_register_count;
    active_load_pc_destination =
      busy && latched_load_pc_destination;
    active_final_word_interlock =
      busy && latched_final_word_interlock;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    data_order_documented = 1'b0;
    instruction_sequential_cycles = 5'd0;
    instruction_nonsequential_cycles = 5'd0;
    instruction_internal_cycles = 5'd0;
    data_sequential_cycles = 5'd0;
    data_nonsequential_cycles = 5'd0;
    data_internal_cycles = 5'd0;
    if (busy) begin
      instruction_sequential_cycles =
        latched_load_pc_destination ? 5'd2 : 5'd1;
      instruction_nonsequential_cycles =
        latched_load_pc_destination ? 5'd1 : 5'd0;
      instruction_internal_cycles =
        cycle_total - instruction_sequential_cycles -
        instruction_nonsequential_cycles;

      if (latched_load_multiple &&
          !latched_load_pc_destination &&
          (latched_register_count == 5'd1)) begin
        // DDI0180A Table 7-2 says S,I for ARM9TDMI. DDI0165B's
        // detailed Table 8-23 says N,I for ARM9E-S.
        if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
          data_sequential_cycles = 5'd1;
        end else begin
          data_nonsequential_cycles = 5'd1;
        end
        data_internal_cycles = 5'd1;
      end else begin
        data_nonsequential_cycles = 5'd1;
        if (latched_register_count > 5'd1) begin
          data_sequential_cycles = latched_register_count - 5'd1;
        end
        data_internal_cycles =
          cycle_total - data_nonsequential_cycles -
          data_sequential_cycles;
      end

      if (PROFILE == ARM9_PROFILE_ARM946ES) begin
        instruction_order_documented = 1'b1;
        data_order_documented = 1'b1;

        if (latched_load_pc_destination) begin
          if (cycle_number <= (latched_register_count + 5'd1)) begin
            instruction_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
          end else if (cycle_number ==
                       (latched_register_count + 5'd2)) begin
            instruction_cycle_type = ARM9_BUS_CYCLE_NONSEQUENTIAL;
          end else begin
            instruction_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
          end
        end else begin
          instruction_cycle_type =
            (cycle_number == cycle_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                            ARM9_BUS_CYCLE_INTERNAL;
        end

        if (cycle_number == 5'd1) begin
          data_cycle_type = ARM9_BUS_CYCLE_NONSEQUENTIAL;
        end else if (cycle_number <= latched_register_count) begin
          data_cycle_type = ARM9_BUS_CYCLE_SEQUENTIAL;
        end else begin
          data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      busy <= 1'b0;
      cycle_number <= 5'd0;
      cycle_total <= 5'd0;
      latched_load_multiple <= 1'b0;
      latched_store_multiple <= 1'b0;
      latched_register_count <= 5'd0;
      latched_load_pc_destination <= 1'b0;
      latched_final_word_interlock <= 1'b0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        if (request_valid) begin
          request_accepted <= 1'b1;
          busy <= 1'b1;
          cycle_number <= 5'd1;
          cycle_total <= requested_cycles;
          latched_load_multiple <= load_multiple;
          latched_store_multiple <= store_multiple;
          latched_register_count <= register_count;
          latched_load_pc_destination <= load_pc_destination;
          latched_final_word_interlock <= final_word_interlock;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        if (cycle_number == cycle_total) begin
          busy <= 1'b0;
          cycle_number <= 5'd0;
          operation_complete <= 1'b1;
        end else begin
          cycle_number <= cycle_number + 5'd1;
        end
      end
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset) begin
      assert (!(request_accepted && request_error));
      assert (!(latched_load_multiple && latched_store_multiple));
      if (busy) begin
        assert ((latched_register_count >= 5'd1) &&
                (latched_register_count <= 5'd16));
        assert ((cycle_number >= 5'd1) &&
                (cycle_number <= cycle_total));
        assert (instruction_sequential_cycles +
                instruction_nonsequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_sequential_cycles +
                data_nonsequential_cycles +
                data_internal_cycles == cycle_total);
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
    end
  end
`endif
endmodule
