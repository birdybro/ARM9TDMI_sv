module arm9_multiplier_timing #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  arm9_isa_pkg::arm9_multiply_kind_e multiply_kind,
  input  logic [23:0]                       multiplier_operand_high,
  input  logic                              set_flags,
  input  logic                              qualified_result_dependency,
  output logic                              profile_legal,
  output logic                              uses_early_termination,
  output logic [2:0]                        early_termination_class,
  output logic                              dependency_interlock_cycles,
  output logic [3:0]                        instruction_cycles
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic long_multiply;
  logic unsigned_long_multiply;
  logic signed_termination;

  always_comb begin
    long_multiply = (multiply_kind == ARM9_MULTIPLY_UMULL) ||
                    (multiply_kind == ARM9_MULTIPLY_UMLAL) ||
                    (multiply_kind == ARM9_MULTIPLY_SMULL) ||
                    (multiply_kind == ARM9_MULTIPLY_SMLAL);
    unsigned_long_multiply = (multiply_kind == ARM9_MULTIPLY_UMULL) ||
                             (multiply_kind == ARM9_MULTIPLY_UMLAL);
    signed_termination = !unsigned_long_multiply;

    profile_legal                = 1'b1;
    uses_early_termination       = 1'b0;
    early_termination_class      = 3'd0;
    dependency_interlock_cycles = 1'b0;
    instruction_cycles          = 4'd0;

    if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
      if ((multiply_kind == ARM9_MULTIPLY_DSP_SHORT) ||
          (multiply_kind == ARM9_MULTIPLY_DSP_LONG)) begin
        profile_legal = 1'b0;
      end else begin
        uses_early_termination = 1'b1;
        if (signed_termination) begin
          if ((multiplier_operand_high == 24'h000000) ||
              (multiplier_operand_high == 24'hffffff)) begin
            early_termination_class = 3'd1;
          end else if ((multiplier_operand_high[23:8] == 16'h0000) ||
                       (multiplier_operand_high[23:8] == 16'hffff)) begin
            early_termination_class = 3'd2;
          end else if ((multiplier_operand_high[23:16] == 8'h00) ||
                       (multiplier_operand_high[23:16] == 8'hff)) begin
            early_termination_class = 3'd3;
          end else begin
            early_termination_class = 3'd4;
          end
        end else begin
          if (multiplier_operand_high == 24'h000000) begin
            early_termination_class = 3'd1;
          end else if (multiplier_operand_high[23:8] == 16'h0000) begin
            early_termination_class = 3'd2;
          end else if (multiplier_operand_high[23:16] == 8'h00) begin
            early_termination_class = 3'd3;
          end else begin
            early_termination_class = 3'd4;
          end
        end

        if (long_multiply) begin
          instruction_cycles = 4'd3 + early_termination_class;
        end else begin
          instruction_cycles = 4'd2 + early_termination_class;
        end
      end
    end else begin
      case (multiply_kind)
        ARM9_MULTIPLY_MUL,
        ARM9_MULTIPLY_MLA: begin
          if (set_flags) begin
            instruction_cycles = 4'd4;
          end else begin
            dependency_interlock_cycles = qualified_result_dependency;
            instruction_cycles = 4'd2 +
                                 {3'b000, dependency_interlock_cycles};
          end
        end
        ARM9_MULTIPLY_UMULL,
        ARM9_MULTIPLY_UMLAL,
        ARM9_MULTIPLY_SMULL,
        ARM9_MULTIPLY_SMLAL: begin
          if (set_flags) begin
            instruction_cycles = 4'd5;
          end else begin
            dependency_interlock_cycles = qualified_result_dependency;
            instruction_cycles = 4'd3 +
                                 {3'b000, dependency_interlock_cycles};
          end
        end
        ARM9_MULTIPLY_DSP_SHORT: begin
          dependency_interlock_cycles = qualified_result_dependency;
          instruction_cycles = 4'd1 +
                               {3'b000, dependency_interlock_cycles};
        end
        ARM9_MULTIPLY_DSP_LONG: begin
          dependency_interlock_cycles = qualified_result_dependency;
          instruction_cycles = 4'd2 +
                               {3'b000, dependency_interlock_cycles};
        end
        default: begin
          profile_legal       = 1'b0;
          instruction_cycles = 'x;
        end
      endcase
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    if (profile_legal) begin
      assert (instruction_cycles != 0);
      assert (!(uses_early_termination &&
                (early_termination_class == 0)));
    end
  end
`endif
endmodule
