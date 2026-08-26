module multiplier_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  arm9_multiply_kind_e multiply_kind;
  logic [23:0]         multiplier_operand_high;
  logic                set_flags;
  logic                qualified_result_dependency;

  logic       tdmi_profile_legal;
  logic       tdmi_uses_early_termination;
  logic [2:0] tdmi_early_termination_class;
  logic       tdmi_dependency_interlock_cycles;
  logic [3:0] tdmi_instruction_cycles;
  logic       arm946_profile_legal;
  logic       arm946_uses_early_termination;
  logic [2:0] arm946_early_termination_class;
  logic       arm946_dependency_interlock_cycles;
  logic [3:0] arm946_instruction_cycles;
  int unsigned cases_checked;

  arm9_multiplier_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .profile_legal(tdmi_profile_legal),
    .uses_early_termination(tdmi_uses_early_termination),
    .early_termination_class(tdmi_early_termination_class),
    .dependency_interlock_cycles(tdmi_dependency_interlock_cycles),
    .instruction_cycles(tdmi_instruction_cycles),
    .*
  );

  arm9_multiplier_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .profile_legal(arm946_profile_legal),
    .uses_early_termination(arm946_uses_early_termination),
    .early_termination_class(arm946_early_termination_class),
    .dependency_interlock_cycles(arm946_dependency_interlock_cycles),
    .instruction_cycles(arm946_instruction_cycles),
    .*
  );

  task automatic expect_tdmi_class(
    input arm9_multiply_kind_e kind,
    input logic [23:0] operand_high,
    input logic [2:0] expected_class
  );
    multiply_kind               = kind;
    multiplier_operand_high     = operand_high;
    set_flags                   = 1'b0;
    qualified_result_dependency = 1'b0;
    #1ps;
    assert (tdmi_profile_legal && tdmi_uses_early_termination);
    assert (tdmi_early_termination_class == expected_class);
    assert (tdmi_dependency_interlock_cycles == 0);
    if ((kind == ARM9_MULTIPLY_MUL) || (kind == ARM9_MULTIPLY_MLA)) begin
      assert (tdmi_instruction_cycles == 2 + expected_class);
    end else begin
      assert (tdmi_instruction_cycles == 3 + expected_class);
    end
    cases_checked++;
  endtask

  task automatic expect_arm946_cycles(
    input arm9_multiply_kind_e kind,
    input logic flags,
    input logic dependency,
    input logic [3:0] expected_cycles
  );
    multiply_kind               = kind;
    multiplier_operand_high     = 24'ha5a55a;
    set_flags                   = flags;
    qualified_result_dependency = dependency;
    #1ps;
    assert (arm946_profile_legal);
    assert (!arm946_uses_early_termination);
    assert (arm946_early_termination_class == 0);
    assert (arm946_instruction_cycles == expected_cycles);
    if (((kind == ARM9_MULTIPLY_DSP_SHORT) ||
         (kind == ARM9_MULTIPLY_DSP_LONG)) || !flags) begin
      assert (arm946_dependency_interlock_cycles == dependency);
    end else begin
      assert (!arm946_dependency_interlock_cycles);
    end
    cases_checked++;
  endtask

  initial begin
    multiply_kind                = ARM9_MULTIPLY_MUL;
    multiplier_operand_high      = '0;
    set_flags                    = 1'b0;
    qualified_result_dependency  = 1'b0;
    cases_checked                = 0;

    // REQ: ARM9TDMI-MULTIPLIER-001
    // REQ: ARM9TDMI-TIMING-MULTERM-001
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h000000, 3'd1);
    expect_tdmi_class(ARM9_MULTIPLY_MLA,   24'h000000, 3'd1);
    expect_tdmi_class(ARM9_MULTIPLY_SMULL, 24'hffffff, 3'd1);
    expect_tdmi_class(ARM9_MULTIPLY_SMLAL, 24'hffffff, 3'd1);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h000001, 3'd2);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h0000ff, 3'd2);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'hffff00, 3'd2);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'hfffffe, 3'd2);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h000100, 3'd3);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h00ffff, 3'd3);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'hff0000, 3'd3);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'hfffeff, 3'd3);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'h010000, 3'd4);
    expect_tdmi_class(ARM9_MULTIPLY_MUL,   24'hfeffff, 3'd4);

    // REQ: ARM9TDMI-TIMING-MULTERM-002
    expect_tdmi_class(ARM9_MULTIPLY_UMULL, 24'h000000, 3'd1);
    expect_tdmi_class(ARM9_MULTIPLY_UMLAL, 24'h000001, 3'd2);
    expect_tdmi_class(ARM9_MULTIPLY_UMULL, 24'h000100, 3'd3);
    expect_tdmi_class(ARM9_MULTIPLY_UMLAL, 24'h010000, 3'd4);
    expect_tdmi_class(ARM9_MULTIPLY_UMULL, 24'hffffff, 3'd4);

    // REQ: ARM946ES-MULTIPLIER-001
    expect_arm946_cycles(ARM9_MULTIPLY_MUL, 1'b0, 1'b0, 4'd2);
    expect_arm946_cycles(ARM9_MULTIPLY_MLA, 1'b0, 1'b1, 4'd3);
    expect_arm946_cycles(ARM9_MULTIPLY_MUL, 1'b1, 1'b0, 4'd4);
    expect_arm946_cycles(ARM9_MULTIPLY_MLA, 1'b1, 1'b1, 4'd4);
    expect_arm946_cycles(ARM9_MULTIPLY_UMULL, 1'b0, 1'b0, 4'd3);
    expect_arm946_cycles(ARM9_MULTIPLY_SMLAL, 1'b0, 1'b1, 4'd4);
    expect_arm946_cycles(ARM9_MULTIPLY_SMULL, 1'b1, 1'b0, 4'd5);
    expect_arm946_cycles(ARM9_MULTIPLY_UMLAL, 1'b1, 1'b1, 4'd5);
    expect_arm946_cycles(ARM9_MULTIPLY_DSP_SHORT, 1'b0, 1'b0, 4'd1);
    expect_arm946_cycles(ARM9_MULTIPLY_DSP_SHORT, 1'b0, 1'b1, 4'd2);
    expect_arm946_cycles(ARM9_MULTIPLY_DSP_LONG, 1'b0, 1'b0, 4'd2);
    expect_arm946_cycles(ARM9_MULTIPLY_DSP_LONG, 1'b0, 1'b1, 4'd3);

    multiply_kind = ARM9_MULTIPLY_DSP_SHORT;
    #1ps;
    assert (!tdmi_profile_legal && tdmi_instruction_cycles == 0);
    cases_checked++;

    assert (cases_checked == 32);
    $display("PASS profile-specific multiply timing and early termination");
    $finish;
  end
endmodule
