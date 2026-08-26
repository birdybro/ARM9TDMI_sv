module arm9_multiply_sequence #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                                 clk,
  input  logic                                 reset,
  input  logic                                 start,
  input  arm9_isa_pkg::arm9_multiply_kind_e    multiply_kind,
  input  logic [23:0]                          multiplier_operand_high,
  input  logic                                 set_flags,
  input  logic                                 qualified_result_dependency,
  output logic                                 ready,
  output logic                                 request_accepted,
  output logic                                 request_error,
  output logic                                 busy,
  output logic                                 cycle_valid,
  output logic [3:0]                           cycle_number,
  output logic [3:0]                           cycle_total,
  output arm9_isa_pkg::arm9_multiply_kind_e    active_multiply_kind,
  output logic                                 active_set_flags,
  output logic                                 active_qualified_dependency,
  output logic                                 active_uses_early_termination,
  output logic [2:0]                           active_early_termination_class,
  output logic                                 active_dependency_interlock,
  output arm9_timing_pkg::arm9_bus_cycle_e    instruction_cycle_type,
  output arm9_timing_pkg::arm9_bus_cycle_e    data_cycle_type,
  output logic                                 instruction_order_documented,
  output logic                                 data_order_documented,
  output logic [3:0]                           instruction_sequential_cycles,
  output logic [3:0]                           instruction_internal_cycles,
  output logic [3:0]                           data_internal_cycles,
  output logic                                 operation_complete
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;
  import arm9_timing_pkg::*;

  logic classifier_profile_legal;
  logic classifier_uses_early_termination;
  logic [2:0] classifier_early_termination_class;
  logic classifier_dependency_interlock;
  logic [3:0] classifier_instruction_cycles;
  arm9_multiply_kind_e latched_multiply_kind;
  logic latched_set_flags;
  logic latched_qualified_dependency;
  logic latched_uses_early_termination;
  logic [2:0] latched_early_termination_class;
  logic latched_dependency_interlock;

  arm9_multiplier_timing #(
    .PROFILE(PROFILE)
  ) latency_classifier (
    .multiply_kind,
    .multiplier_operand_high,
    .set_flags,
    .qualified_result_dependency,
    .profile_legal(classifier_profile_legal),
    .uses_early_termination(classifier_uses_early_termination),
    .early_termination_class(classifier_early_termination_class),
    .dependency_interlock_cycles(classifier_dependency_interlock),
    .instruction_cycles(classifier_instruction_cycles)
  );

  always_comb begin
    ready = !busy;
    cycle_valid = busy;
    active_multiply_kind = latched_multiply_kind;
    active_set_flags = busy && latched_set_flags;
    active_qualified_dependency =
      busy && latched_qualified_dependency;
    active_uses_early_termination =
      busy && latched_uses_early_termination;
    active_early_termination_class =
      busy ? latched_early_termination_class : 3'd0;
    active_dependency_interlock =
      busy && latched_dependency_interlock;

    instruction_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    data_cycle_type = ARM9_BUS_CYCLE_UNSPECIFIED;
    instruction_order_documented = 1'b0;
    data_order_documented = 1'b0;
    instruction_sequential_cycles = 4'd0;
    instruction_internal_cycles = 4'd0;
    data_internal_cycles = 4'd0;
    if (busy) begin
      instruction_sequential_cycles = 4'd1;
      instruction_internal_cycles = cycle_total - 4'd1;
      data_internal_cycles = cycle_total;
      data_cycle_type = ARM9_BUS_CYCLE_INTERNAL;
      data_order_documented = 1'b1;

      // DDI0165B Tables 8-11 through 8-16 publish exact ARM9E-S order.
      // DDI0180A Table 7-2 publishes only ARM9TDMI aggregate counts.
      if (PROFILE == ARM9_PROFILE_ARM946ES) begin
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
      cycle_number <= 4'd0;
      cycle_total <= 4'd0;
      latched_multiply_kind <= ARM9_MULTIPLY_MUL;
      latched_set_flags <= 1'b0;
      latched_qualified_dependency <= 1'b0;
      latched_uses_early_termination <= 1'b0;
      latched_early_termination_class <= 3'd0;
      latched_dependency_interlock <= 1'b0;
      operation_complete <= 1'b0;
    end else begin
      request_accepted <= 1'b0;
      request_error <= 1'b0;
      operation_complete <= 1'b0;

      if (start && !busy) begin
        if (classifier_profile_legal) begin
          request_accepted <= 1'b1;
          busy <= 1'b1;
          cycle_number <= 4'd1;
          cycle_total <= classifier_instruction_cycles;
          latched_multiply_kind <= multiply_kind;
          latched_set_flags <= set_flags;
          latched_qualified_dependency <= qualified_result_dependency;
          latched_uses_early_termination <=
            classifier_uses_early_termination;
          latched_early_termination_class <=
            classifier_early_termination_class;
          latched_dependency_interlock <=
            classifier_dependency_interlock;
        end else begin
          request_error <= 1'b1;
        end
      end else if (busy) begin
        if (cycle_number == cycle_total) begin
          busy <= 1'b0;
          cycle_number <= 4'd0;
          cycle_total <= 4'd0;
          operation_complete <= 1'b1;
        end else begin
          cycle_number <= cycle_number + 4'd1;
        end
      end
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset) begin
      assert (!(request_accepted && request_error));
      if (busy) begin
        assert ((cycle_total >= 4'd1) && (cycle_total <= 4'd7));
        assert ((cycle_number >= 4'd1) &&
                (cycle_number <= cycle_total));
        assert (instruction_sequential_cycles +
                instruction_internal_cycles == cycle_total);
        assert (data_internal_cycles == cycle_total);
        assert (data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
        assert (data_order_documented);
        if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
          assert (active_uses_early_termination);
          assert ((active_early_termination_class >= 3'd1) &&
                  (active_early_termination_class <= 3'd4));
          assert (!instruction_order_documented);
          assert (instruction_cycle_type ==
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end else begin
          assert (!active_uses_early_termination);
          assert (active_early_termination_class == 3'd0);
          assert (instruction_order_documented);
          assert (instruction_cycle_type !=
                  ARM9_BUS_CYCLE_UNSPECIFIED);
        end
      end
    end
  end
`endif
endmodule
