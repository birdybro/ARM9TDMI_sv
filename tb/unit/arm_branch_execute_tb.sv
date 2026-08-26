module arm_branch_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] instruction_address;
  logic [31:0] register_target;
  logic        negative;
  logic        zero;
  logic        carry;
  logic        overflow;

  logic        tdmi_decode_match;
  logic        tdmi_profile_legal;
  logic        tdmi_profile_illegal_encoding;
  logic        tdmi_condition_passed;
  logic        tdmi_unconditional_space;
  logic        tdmi_branch_taken;
  arm9_branch_kind_e tdmi_branch_kind;
  logic [31:0] tdmi_branch_target;
  logic        tdmi_branch_thumb_state;
  logic        tdmi_link_write_enable;
  logic [31:0] tdmi_link_value;
  logic        tdmi_unpredictable_behavior;

  logic        arm946_decode_match;
  logic        arm946_profile_legal;
  logic        arm946_profile_illegal_encoding;
  logic        arm946_condition_passed;
  logic        arm946_unconditional_space;
  logic        arm946_branch_taken;
  arm9_branch_kind_e arm946_branch_kind;
  logic [31:0] arm946_branch_target;
  logic        arm946_branch_thumb_state;
  logic        arm946_link_write_enable;
  logic [31:0] arm946_link_value;
  logic        arm946_unpredictable_behavior;
  int unsigned cases_checked;

  arm9_arm_branch_execute #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .condition_passed(tdmi_condition_passed),
    .unconditional_space(tdmi_unconditional_space),
    .branch_taken(tdmi_branch_taken),
    .branch_kind(tdmi_branch_kind),
    .branch_target(tdmi_branch_target),
    .branch_thumb_state(tdmi_branch_thumb_state),
    .link_write_enable(tdmi_link_write_enable),
    .link_value(tdmi_link_value),
    .unpredictable_behavior(tdmi_unpredictable_behavior),
    .*
  );

  arm9_arm_branch_execute #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .condition_passed(arm946_condition_passed),
    .unconditional_space(arm946_unconditional_space),
    .branch_taken(arm946_branch_taken),
    .branch_kind(arm946_branch_kind),
    .branch_target(arm946_branch_target),
    .branch_thumb_state(arm946_branch_thumb_state),
    .link_write_enable(arm946_link_write_enable),
    .link_value(arm946_link_value),
    .unpredictable_behavior(arm946_unpredictable_behavior),
    .*
  );

  task automatic set_immediate_branch(
    input logic [3:0] condition,
    input logic link_or_h,
    input logic [23:0] immediate
  );
    instruction        = '0;
    instruction[31:28] = condition;
    instruction[27:25] = 3'b101;
    instruction[24]    = link_or_h;
    instruction[23:0]  = immediate;
  endtask

  initial begin
    instruction         = '0;
    instruction_address = 32'h0000_1000;
    register_target     = '0;
    negative            = 1'b0;
    zero                = 1'b0;
    carry               = 1'b0;
    overflow            = 1'b0;
    cases_checked       = 0;

    // REQ: COMMON-ARM-BRANCH-001
    set_immediate_branch(4'he, 1'b0, 24'h000000);
    #1ps;
    assert (tdmi_decode_match && tdmi_profile_legal && tdmi_branch_taken);
    assert (tdmi_branch_kind == ARM9_BRANCH_B);
    assert (tdmi_branch_target == 32'h0000_1008);
    assert (!tdmi_branch_thumb_state && !tdmi_link_write_enable);
    assert (!tdmi_unconditional_space);
    assert (!tdmi_unpredictable_behavior);
    cases_checked++;

    set_immediate_branch(4'he, 1'b1, 24'hfffffe);
    #1ps;
    assert (tdmi_branch_kind == ARM9_BRANCH_BL);
    assert (tdmi_branch_target == instruction_address);
    assert (tdmi_link_write_enable && tdmi_link_value == 32'h0000_1004);
    assert (arm946_branch_target == tdmi_branch_target);
    cases_checked++;

    set_immediate_branch(4'h0, 1'b1, 24'h000001);
    zero = 1'b0;
    #1ps;
    assert (!tdmi_condition_passed && !tdmi_branch_taken);
    assert (!tdmi_link_write_enable);
    cases_checked++;

    // REQ: COMMON-ARM-BX-001
    instruction = 32'he12f_ff10;
    for (int unsigned low_bits = 0; low_bits < 4; low_bits++) begin
      register_target = 32'h2000_0000 | low_bits;
      #1ps;
      assert (tdmi_decode_match && tdmi_profile_legal);
      assert (tdmi_branch_kind == ARM9_BRANCH_BX);
      assert (tdmi_branch_target == {register_target[31:1], 1'b0});
      assert (tdmi_branch_thumb_state == register_target[0]);
      assert (tdmi_unpredictable_behavior ==
              (!register_target[0] && register_target[1]));
      assert (tdmi_branch_taken == !tdmi_unpredictable_behavior);
      cases_checked++;
    end

    // REQ: ARM946ES-ARM-BLX-001
    // REQ: ARM9TDMI-NO-BLX-001
    instruction_address = 32'h1000_0000;
    set_immediate_branch(4'hf, 1'b1, 24'h000001);
    #1ps;
    assert (tdmi_decode_match && !tdmi_profile_legal);
    assert (tdmi_profile_illegal_encoding && !tdmi_branch_taken);
    assert (arm946_decode_match && arm946_profile_legal);
    assert (!arm946_profile_illegal_encoding && arm946_branch_taken);
    assert (arm946_branch_kind == ARM9_BRANCH_BLX_IMMEDIATE);
    assert (arm946_branch_target == 32'h1000_000e);
    assert (arm946_branch_thumb_state && arm946_link_write_enable);
    assert (arm946_link_value == 32'h1000_0004);
    assert (arm946_unconditional_space && arm946_condition_passed);
    cases_checked++;

    instruction     = 32'he12f_ff30;
    register_target = 32'h3000_0001;
    #1ps;
    assert (tdmi_decode_match && !tdmi_profile_legal);
    assert (tdmi_profile_illegal_encoding && !tdmi_branch_taken);
    assert (arm946_profile_legal && arm946_branch_taken);
    assert (arm946_branch_kind == ARM9_BRANCH_BLX_REGISTER);
    assert (arm946_branch_target == 32'h3000_0000);
    assert (arm946_branch_thumb_state && arm946_link_write_enable);
    cases_checked++;

    // Crossing the 32-bit address-space boundary is architecturally
    // UNPREDICTABLE and must not silently commit a branch.
    instruction_address = 32'hffff_fffc;
    set_immediate_branch(4'he, 1'b0, 24'h000001);
    #1ps;
    assert (tdmi_unpredictable_behavior && !tdmi_branch_taken);
    assert (arm946_unpredictable_behavior && !arm946_branch_taken);
    cases_checked++;

    assert (cases_checked == 10);
    $display("PASS profile-specific ARM B/BL/BX/BLX behavior");
    $finish;
  end
endmodule
