module dsp_multiply_decoder_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic [3:0] tdmi_condition;
  arm9_dsp_multiply_kind_e tdmi_dsp_multiply_kind;
  arm9_multiply_kind_e tdmi_timing_kind;
  logic tdmi_x_bit;
  logic tdmi_y_bit;
  logic [3:0] tdmi_destination_high_register;
  logic [3:0] tdmi_accumulator_or_low_register;
  logic [3:0] tdmi_multiplier_register;
  logic [3:0] tdmi_multiplicand_register;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic [3:0] arm946_condition;
  arm9_dsp_multiply_kind_e arm946_dsp_multiply_kind;
  arm9_multiply_kind_e arm946_timing_kind;
  logic arm946_x_bit;
  logic arm946_y_bit;
  logic [3:0] arm946_destination_high_register;
  logic [3:0] arm946_accumulator_or_low_register;
  logic [3:0] arm946_multiplier_register;
  logic [3:0] arm946_multiplicand_register;
  int unsigned cases_checked;

  arm9_dsp_multiply_decoder #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .condition(tdmi_condition),
    .dsp_multiply_kind(tdmi_dsp_multiply_kind),
    .timing_kind(tdmi_timing_kind),
    .x_bit(tdmi_x_bit),
    .y_bit(tdmi_y_bit),
    .destination_high_register(tdmi_destination_high_register),
    .accumulator_or_low_register(tdmi_accumulator_or_low_register),
    .multiplier_register(tdmi_multiplier_register),
    .multiplicand_register(tdmi_multiplicand_register),
    .*
  );

  arm9_dsp_multiply_decoder #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .condition(arm946_condition),
    .dsp_multiply_kind(arm946_dsp_multiply_kind),
    .timing_kind(arm946_timing_kind),
    .x_bit(arm946_x_bit),
    .y_bit(arm946_y_bit),
    .destination_high_register(arm946_destination_high_register),
    .accumulator_or_low_register(arm946_accumulator_or_low_register),
    .multiplier_register(arm946_multiplier_register),
    .multiplicand_register(arm946_multiplicand_register),
    .*
  );

  task automatic set_valid_kind(
    input arm9_dsp_multiply_kind_e kind
  );
    instruction        = 32'he100_0080;
    instruction[19:16] = 4'h1;
    instruction[15:12] = 4'h2;
    instruction[11:8]  = 4'h3;
    instruction[3:0]   = 4'h4;
    case (kind)
      ARM9_DSP_MULTIPLY_SMLA_XY: instruction[23:21] = 3'b000;
      ARM9_DSP_MULTIPLY_SMLAW_Y: begin
        instruction[23:21] = 3'b001;
        instruction[5]     = 1'b0;
      end
      ARM9_DSP_MULTIPLY_SMULW_Y: begin
        instruction[23:21] = 3'b001;
        instruction[5]     = 1'b1;
        instruction[15:12] = 4'h0;
      end
      ARM9_DSP_MULTIPLY_SMLAL_XY: instruction[23:21] = 3'b010;
      default: begin
        instruction[23:21] = 3'b011;
        instruction[15:12] = 4'h0;
      end
    endcase
  endtask

  task automatic expect_arm946_unpredictable;
    #1ps;
    assert (arm946_decode_match && arm946_profile_legal);
    assert (arm946_unpredictable_encoding && !arm946_encoding_valid);
    assert (tdmi_decode_match && !tdmi_profile_legal);
    assert (tdmi_profile_illegal_encoding && !tdmi_encoding_valid);
    cases_checked++;
  endtask

  initial begin
    instruction   = '0;
    cases_checked = 0;

    // REQ: ARM946ES-DSP-MULTIPLY-DECODE-001
    // REQ: ARM9TDMI-NO-DSP-MULTIPLY-001
    for (int unsigned control = 0; control < 256; control++) begin
      for (int unsigned extension = 0; extension < 16; extension++) begin
        logic expected_match;
        logic uses_low_field;
        arm9_dsp_multiply_kind_e expected_kind;

        expected_match = (control[7:4] == 4'b0001) && !control[0] &&
                         (control[3:1] <= 3'b011) && extension[3] &&
                         !extension[0];
        case (control[3:1])
          3'b000: expected_kind = ARM9_DSP_MULTIPLY_SMLA_XY;
          3'b001: begin
            expected_kind = extension[1] ? ARM9_DSP_MULTIPLY_SMULW_Y :
                                           ARM9_DSP_MULTIPLY_SMLAW_Y;
          end
          3'b010: expected_kind = ARM9_DSP_MULTIPLY_SMLAL_XY;
          default: expected_kind = ARM9_DSP_MULTIPLY_SMUL_XY;
        endcase
        uses_low_field = (expected_kind == ARM9_DSP_MULTIPLY_SMLA_XY) ||
                         (expected_kind == ARM9_DSP_MULTIPLY_SMLAW_Y) ||
                         (expected_kind == ARM9_DSP_MULTIPLY_SMLAL_XY);

        instruction        = 32'he000_0000;
        instruction[27:20] = control[7:0];
        instruction[19:16] = 4'h1;
        instruction[15:12] = uses_low_field ? 4'h2 : 4'h0;
        instruction[11:8]  = 4'h3;
        instruction[7:4]   = extension[3:0];
        instruction[3:0]   = 4'h4;
        #1ps;

        assert (tdmi_decode_match == expected_match);
        assert (!tdmi_profile_legal && !tdmi_encoding_valid);
        assert (tdmi_profile_illegal_encoding == expected_match);
        assert (!tdmi_unpredictable_encoding);
        assert (arm946_decode_match == expected_match);
        assert (arm946_profile_legal == expected_match);
        assert (arm946_encoding_valid == expected_match);
        assert (!arm946_profile_illegal_encoding);
        assert (!arm946_unpredictable_encoding);
        assert (tdmi_dsp_multiply_kind == expected_kind);
        assert (arm946_dsp_multiply_kind == expected_kind);
        assert (tdmi_timing_kind == arm946_timing_kind);
        assert (arm946_timing_kind ==
                ((expected_kind == ARM9_DSP_MULTIPLY_SMLAL_XY) ?
                 ARM9_MULTIPLY_DSP_LONG : ARM9_MULTIPLY_DSP_SHORT));
        assert (tdmi_condition == 4'he && arm946_condition == 4'he);
        assert (tdmi_x_bit == extension[1]);
        assert (arm946_x_bit == extension[1]);
        assert (tdmi_y_bit == extension[2]);
        assert (arm946_y_bit == extension[2]);
        assert (tdmi_destination_high_register == 4'h1);
        assert (arm946_destination_high_register == 4'h1);
        assert (tdmi_accumulator_or_low_register ==
                (uses_low_field ? 4'h2 : 4'h0));
        assert (arm946_accumulator_or_low_register ==
                tdmi_accumulator_or_low_register);
        assert (tdmi_multiplier_register == 4'h3);
        assert (arm946_multiplier_register == 4'h3);
        assert (tdmi_multiplicand_register == 4'h4);
        assert (arm946_multiplicand_register == 4'h4);
        cases_checked++;
      end
    end

    // REQ: ARM946ES-DSP-MULTIPLY-OPERANDS-001
    for (int unsigned kind = 0; kind < 5; kind++) begin
      for (int unsigned field = 0; field < 4; field++) begin
        set_valid_kind(arm9_dsp_multiply_kind_e'(kind[2:0]));
        case (field)
          0: instruction[19:16] = 4'hf;
          1: instruction[15:12] = 4'hf;
          2: instruction[11:8]  = 4'hf;
          default: instruction[3:0] = 4'hf;
        endcase
        expect_arm946_unpredictable();
      end
    end

    set_valid_kind(ARM9_DSP_MULTIPLY_SMULW_Y);
    instruction[15:12] = 4'h1;
    expect_arm946_unpredictable();

    set_valid_kind(ARM9_DSP_MULTIPLY_SMUL_XY);
    instruction[15:12] = 4'h1;
    expect_arm946_unpredictable();

    set_valid_kind(ARM9_DSP_MULTIPLY_SMLAL_XY);
    instruction[15:12] = instruction[19:16];
    expect_arm946_unpredictable();

    set_valid_kind(ARM9_DSP_MULTIPLY_SMLA_XY);
    instruction[31:28] = 4'hf;
    #1ps;
    assert (!tdmi_decode_match && !arm946_decode_match);
    assert (!tdmi_encoding_valid && !arm946_encoding_valid);
    cases_checked++;

    assert (cases_checked == 4_120);
    $display("PASS exhaustive profile-specific ARMv5TE DSP multiply decode");
    $finish;
  end
endmodule
