module arm9_arm_branch_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0]                  instruction,
  input  logic [31:0]                  instruction_address,
  input  logic [31:0]                  register_target,
  input  logic                         negative,
  input  logic                         zero,
  input  logic                         carry,
  input  logic                         overflow,
  output logic                         decode_match,
  output logic                         profile_legal,
  output logic                         profile_illegal_encoding,
  output logic                         condition_passed,
  output logic                         unconditional_space,
  output logic                         branch_taken,
  output arm9_isa_pkg::arm9_branch_kind_e branch_kind,
  output logic [31:0]                  branch_target,
  output logic                         branch_thumb_state,
  output logic                         link_write_enable,
  output logic [31:0]                  link_value,
  output logic                         unpredictable_behavior
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic        is_immediate_branch;
  logic        is_bx;
  logic        is_blx_register;
  logic        condition_result;
  logic        condition_unconditional;
  logic [31:0] immediate_offset;
  logic signed [32:0] target_wide;
  logic        target_wrap;
  logic        target_alignment_unpredictable;
  logic        unconditional_branch;

  arm9_condition_eval condition_evaluator (
    .condition(instruction[31:28]),
    .flag_n(negative),
    .flag_z(zero),
    .flag_c(carry),
    .flag_v(overflow),
    .condition_passed(condition_result),
    .unconditional_space(condition_unconditional)
  );

  always_comb begin
    is_immediate_branch = instruction[27:25] == 3'b101;
    is_bx               = instruction[27:4] == 24'h12fff1;
    is_blx_register     = instruction[27:4] == 24'h12fff3;
    immediate_offset    = {{6{instruction[23]}}, instruction[23:0], 2'b00};

    decode_match                     = 1'b0;
    profile_legal                    = 1'b0;
    profile_illegal_encoding         = 1'b0;
    unconditional_branch             = 1'b0;
    branch_kind                      = ARM9_BRANCH_B;
    branch_target                    = '0;
    branch_thumb_state               = 1'b0;
    link_value                       = instruction_address + 32'd4;
    target_wide                      = '0;
    target_wrap                      = 1'b0;
    target_alignment_unpredictable   = 1'b0;

    if (is_bx) begin
      decode_match = 1'b1;
      branch_kind  = ARM9_BRANCH_BX;
      if (!condition_unconditional) begin
        profile_legal = 1'b1;
      end else begin
        profile_illegal_encoding = 1'b1;
      end
      branch_target                  = {register_target[31:1], 1'b0};
      branch_thumb_state             = register_target[0];
      target_alignment_unpredictable = !register_target[0] &&
                                       register_target[1];
    end else if (is_blx_register) begin
      decode_match = 1'b1;
      branch_kind  = ARM9_BRANCH_BLX_REGISTER;
      if ((PROFILE == ARM9_PROFILE_ARM946ES) &&
          !condition_unconditional) begin
        profile_legal = 1'b1;
      end else begin
        profile_illegal_encoding = 1'b1;
      end
      branch_target                  = {register_target[31:1], 1'b0};
      branch_thumb_state             = register_target[0];
      target_alignment_unpredictable = !register_target[0] &&
                                       register_target[1];
    end else if (is_immediate_branch) begin
      decode_match = 1'b1;
      if (condition_unconditional) begin
        branch_kind          = ARM9_BRANCH_BLX_IMMEDIATE;
        unconditional_branch = 1'b1;
        branch_thumb_state   = 1'b1;
        if (PROFILE == ARM9_PROFILE_ARM946ES) begin
          profile_legal = 1'b1;
        end else begin
          profile_illegal_encoding = 1'b1;
        end
        target_wide = $signed({1'b0, instruction_address}) + 33'sd8 +
                      $signed({immediate_offset[31], immediate_offset}) +
                      $signed({31'b0, instruction[24], 1'b0});
      end else begin
        branch_kind = instruction[24] ? ARM9_BRANCH_BL : ARM9_BRANCH_B;
        profile_legal = 1'b1;
        target_wide = $signed({1'b0, instruction_address}) + 33'sd8 +
                      $signed({immediate_offset[31], immediate_offset});
      end
      branch_target = target_wide[31:0];
      target_wrap   = target_wide[32];
    end

    condition_passed = unconditional_branch || condition_result;
    unconditional_space = condition_unconditional;
    unpredictable_behavior = target_wrap ||
                             target_alignment_unpredictable;
    branch_taken = decode_match && profile_legal && condition_passed &&
                   !unpredictable_behavior;
    link_write_enable = branch_taken &&
      ((branch_kind == ARM9_BRANCH_BL) ||
       (branch_kind == ARM9_BRANCH_BLX_IMMEDIATE) ||
       (branch_kind == ARM9_BRANCH_BLX_REGISTER));
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(branch_taken && !profile_legal));
    assert (!(link_write_enable && !branch_taken));
  end
`endif
endmodule
