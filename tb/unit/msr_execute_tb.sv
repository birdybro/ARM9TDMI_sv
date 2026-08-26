module msr_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_arch_pkg::*;

  logic [31:0] instruction;
  arm9_mode_e current_mode;
  logic [31:0] register_operand_value;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;

  logic tdmi_decode_match;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic tdmi_condition_passed;
  logic tdmi_unconditional_space;
  logic tdmi_immediate_operand;
  logic tdmi_spsr_select;
  logic [3:0] tdmi_field_mask;
  logic [3:0] tdmi_source_register;
  logic [31:0] tdmi_operand_value;
  logic tdmi_unpredictable_operation;
  logic tdmi_execute_valid;
  logic tdmi_cpsr_write_valid;
  logic tdmi_spsr_write_valid;
  logic [31:0] tdmi_psr_write_data;
  logic [31:0] tdmi_psr_write_mask;
  logic tdmi_flags_only_timing_class;
  logic tdmi_other_timing_class;

  logic arm946_decode_match;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic arm946_condition_passed;
  logic arm946_unconditional_space;
  logic arm946_immediate_operand;
  logic arm946_spsr_select;
  logic [3:0] arm946_field_mask;
  logic [3:0] arm946_source_register;
  logic [31:0] arm946_operand_value;
  logic arm946_unpredictable_operation;
  logic arm946_execute_valid;
  logic arm946_cpsr_write_valid;
  logic arm946_spsr_write_valid;
  logic [31:0] arm946_psr_write_data;
  logic [31:0] arm946_psr_write_mask;
  logic arm946_flags_only_timing_class;
  logic arm946_other_timing_class;
  int unsigned cases_checked;

  arm9_msr_execute #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .instruction,
    .current_mode,
    .register_operand_value,
    .negative,
    .zero,
    .carry,
    .overflow,
    .decode_match(tdmi_decode_match),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .condition_passed(tdmi_condition_passed),
    .unconditional_space(tdmi_unconditional_space),
    .immediate_operand(tdmi_immediate_operand),
    .spsr_select(tdmi_spsr_select),
    .field_mask(tdmi_field_mask),
    .source_register(tdmi_source_register),
    .operand_value(tdmi_operand_value),
    .unpredictable_operation(tdmi_unpredictable_operation),
    .execute_valid(tdmi_execute_valid),
    .cpsr_write_valid(tdmi_cpsr_write_valid),
    .spsr_write_valid(tdmi_spsr_write_valid),
    .psr_write_data(tdmi_psr_write_data),
    .psr_write_mask(tdmi_psr_write_mask),
    .flags_only_timing_class(tdmi_flags_only_timing_class),
    .other_timing_class(tdmi_other_timing_class)
  );

  arm9_msr_execute #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .instruction,
    .current_mode,
    .register_operand_value,
    .negative,
    .zero,
    .carry,
    .overflow,
    .decode_match(arm946_decode_match),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .condition_passed(arm946_condition_passed),
    .unconditional_space(arm946_unconditional_space),
    .immediate_operand(arm946_immediate_operand),
    .spsr_select(arm946_spsr_select),
    .field_mask(arm946_field_mask),
    .source_register(arm946_source_register),
    .operand_value(arm946_operand_value),
    .unpredictable_operation(arm946_unpredictable_operation),
    .execute_valid(arm946_execute_valid),
    .cpsr_write_valid(arm946_cpsr_write_valid),
    .spsr_write_valid(arm946_spsr_write_valid),
    .psr_write_data(arm946_psr_write_data),
    .psr_write_mask(arm946_psr_write_mask),
    .flags_only_timing_class(arm946_flags_only_timing_class),
    .other_timing_class(arm946_other_timing_class)
  );

  function automatic logic reference_condition(
    input logic [3:0] cond,
    input logic n,
    input logic z,
    input logic c,
    input logic v
  );
    case (cond)
      4'h0: return z;
      4'h1: return !z;
      4'h2: return c;
      4'h3: return !c;
      4'h4: return n;
      4'h5: return !n;
      4'h6: return v;
      4'h7: return !v;
      4'h8: return c && !z;
      4'h9: return !c || z;
      4'ha: return n == v;
      4'hb: return n != v;
      4'hc: return !z && (n == v);
      4'hd: return z || (n != v);
      4'he: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic arm9_mode_e mode_for_case(input int unsigned value);
    case (value)
      0: return ARM9_MODE_USER;
      1: return ARM9_MODE_FIQ;
      2: return ARM9_MODE_IRQ;
      3: return ARM9_MODE_SUPERVISOR;
      4: return ARM9_MODE_ABORT;
      5: return ARM9_MODE_UNDEFINED;
      default: return ARM9_MODE_SYSTEM;
    endcase
  endfunction

  function automatic logic valid_mode_bits(input logic [4:0] mode_bits);
    case (mode_bits)
      5'h10, 5'h11, 5'h12, 5'h13, 5'h17, 5'h1b, 5'h1f:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic [31:0] operand_for_case(input int unsigned value);
    case (value)
      0:  return 32'h0000_0000;
      1:  return 32'hf000_0000;
      2:  return 32'h0800_0000;
      3:  return 32'h0400_0000;
      4:  return 32'h0000_0100;
      5:  return 32'h0000_0020;
      6:  return 32'h0000_0080;
      7:  return 32'h0000_0040;
      8:  return 32'h0000_00d3;
      9:  return 32'h0000_0013;
      10: return 32'h0000_001a;
      11: return 32'hffff_ffff;
      12: return 32'hf800_00df;
      13: return 32'h8000_00d2;
      14: return 32'h5000_00db;
      default: return 32'h0000_001f;
    endcase
  endfunction

  function automatic logic [31:0] rotate_immediate(
    input logic [7:0] immediate,
    input logic [3:0] rotate
  );
    logic [31:0] unrotated;
    int unsigned amount;
    unrotated = {24'b0, immediate};
    amount = rotate * 2;
    if (amount == 0) begin
      return unrotated;
    end
    return (unrotated >> amount) | (unrotated << (32 - amount));
  endfunction

  task automatic check_profile(
    input logic        arm946_profile,
    input logic [31:0] actual_operand,
    input logic        actual_unpredictable,
    input logic        actual_execute,
    input logic        actual_cpsr_write,
    input logic        actual_spsr_write,
    input logic [31:0] actual_write_data,
    input logic [31:0] actual_write_mask,
    input logic        actual_flags_class,
    input logic        actual_other_class
  );
    logic expected_condition;
    logic expected_active;
    logic expected_privileged;
    logic expected_has_spsr;
    logic expected_unpredictable;
    logic expected_execute;
    logic [31:0] expected_unallocated_mask;
    logic [31:0] expected_user_mask;
    logic [31:0] expected_allowed_mask;
    logic [31:0] expected_byte_mask;
    logic [31:0] expected_effective_mask;

    expected_condition = reference_condition(
      instruction[31:28], negative, zero, carry, overflow
    );
    expected_active = expected_condition &&
                      (instruction[21:20] == 2'b10);
    expected_privileged = current_mode != ARM9_MODE_USER;
    expected_has_spsr = (current_mode != ARM9_MODE_USER) &&
                        (current_mode != ARM9_MODE_SYSTEM);
    expected_unallocated_mask = arm946_profile ? 32'h07ff_ff00 :
                                                32'h0fff_ff00;
    expected_user_mask = arm946_profile ? 32'hf800_0000 :
                                         32'hf000_0000;
    expected_byte_mask = {
      {8{instruction[19]}},
      {8{instruction[18]}},
      {8{instruction[17]}},
      {8{instruction[16]}}
    };
    if (instruction[22]) begin
      expected_allowed_mask = expected_user_mask | 32'h0000_00ff;
    end else if (expected_privileged) begin
      expected_allowed_mask = expected_user_mask | 32'h0000_00df;
    end else begin
      expected_allowed_mask = expected_user_mask;
    end
    expected_effective_mask = expected_byte_mask & expected_allowed_mask;
    expected_unpredictable = expected_active &&
      (((actual_operand & expected_unallocated_mask) != 0) ||
       (instruction[22] && !expected_has_spsr) ||
       (!instruction[22] && expected_privileged && actual_operand[5]) ||
       (instruction[16] && !valid_mode_bits(actual_operand[4:0]) &&
        (instruction[22] ? expected_has_spsr : expected_privileged)));
    expected_execute = expected_active && !expected_unpredictable;

    assert (actual_unpredictable == expected_unpredictable);
    assert (actual_execute == expected_execute);
    assert (actual_cpsr_write ==
            (expected_execute && !instruction[22] &&
             (expected_effective_mask != 0)));
    assert (actual_spsr_write ==
            (expected_execute && instruction[22] &&
             (expected_effective_mask != 0)));
    assert (actual_write_data == actual_operand);
    assert (actual_write_mask ==
            (expected_execute ? expected_effective_mask : 32'b0));
    assert (actual_flags_class ==
            (expected_execute && (instruction[19:16] == 4'b1000)));
    assert (actual_other_class ==
            (expected_execute && (instruction[19:16] != 4'b1000)));
  endtask

  task automatic check_both_profiles;
    begin
      assert (tdmi_decode_match && arm946_decode_match);
      assert (tdmi_encoding_valid && arm946_encoding_valid);
      assert (!tdmi_unpredictable_encoding &&
              !arm946_unpredictable_encoding);
      assert (tdmi_condition_passed == arm946_condition_passed);
      assert (tdmi_unconditional_space == arm946_unconditional_space);
      assert (tdmi_immediate_operand == instruction[25]);
      assert (arm946_immediate_operand == instruction[25]);
      assert (tdmi_spsr_select == instruction[22]);
      assert (arm946_spsr_select == instruction[22]);
      assert (tdmi_field_mask == instruction[19:16]);
      assert (arm946_field_mask == instruction[19:16]);
      assert (tdmi_source_register == instruction[3:0]);
      assert (arm946_source_register == instruction[3:0]);
      assert (tdmi_operand_value == arm946_operand_value);
      check_profile(
        1'b0,
        tdmi_operand_value,
        tdmi_unpredictable_operation,
        tdmi_execute_valid,
        tdmi_cpsr_write_valid,
        tdmi_spsr_write_valid,
        tdmi_psr_write_data,
        tdmi_psr_write_mask,
        tdmi_flags_only_timing_class,
        tdmi_other_timing_class
      );
      check_profile(
        1'b1,
        arm946_operand_value,
        arm946_unpredictable_operation,
        arm946_execute_valid,
        arm946_cpsr_write_valid,
        arm946_spsr_write_valid,
        arm946_psr_write_data,
        arm946_psr_write_mask,
        arm946_flags_only_timing_class,
        arm946_other_timing_class
      );
      cases_checked++;
    end
  endtask

  initial begin
    instruction = 32'he121_f000;
    current_mode = ARM9_MODE_SUPERVISOR;
    register_operand_value = 32'b0;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MSR-EXECUTE-001
    // REQ: COMMON-ARM-MSR-PRIVILEGE-001
    // REQ: ARM9TDMI-ARM-MSR-MASK-001
    // REQ: ARM946ES-ARM-MSR-MASK-001
    for (int unsigned condition_case = 0; condition_case < 15;
         condition_case++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        for (int unsigned mode_case = 0; mode_case < 7; mode_case++) begin
          for (int unsigned target_case = 0; target_case < 2;
               target_case++) begin
            for (int unsigned mask_case = 0; mask_case < 16;
                 mask_case++) begin
              for (int unsigned operand_case = 0; operand_case < 16;
                   operand_case++) begin
                instruction = {
                  condition_case[3:0], 5'b00010, target_case[0],
                  2'b10, mask_case[3:0], 12'hf00, operand_case[3:0]
                };
                current_mode = mode_for_case(mode_case);
                register_operand_value = operand_for_case(operand_case);
                negative = flags[3];
                zero = flags[2];
                carry = flags[1];
                overflow = flags[0];
                #1ps;
                check_both_profiles();
              end
            end
          end
        end
      end
    end

    // REQ: COMMON-ARM-MSR-IMMEDIATE-001
    current_mode = ARM9_MODE_SUPERVISOR;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b1;
    overflow = 1'b0;
    for (int unsigned target_case = 0; target_case < 2;
         target_case++) begin
      for (int unsigned mask_case = 0; mask_case < 16;
           mask_case++) begin
        for (int unsigned rotate_case = 0; rotate_case < 16;
             rotate_case++) begin
          for (int unsigned immediate_case = 0; immediate_case < 256;
               immediate_case++) begin
            instruction = {
              4'he, 5'b00110, target_case[0], 2'b10,
              mask_case[3:0], 4'hf, rotate_case[3:0],
              immediate_case[7:0]
            };
            #1ps;
            assert (tdmi_operand_value == rotate_immediate(
              immediate_case[7:0], rotate_case[3:0]
            ));
            check_both_profiles();
          end
        end
      end
    end

    // Failed conditions suppress all architectural constraints and writes.
    instruction = 32'h0121_f000;
    current_mode = ARM9_MODE_USER;
    register_operand_value = 32'hffff_ffff;
    zero = 1'b0;
    #1ps;
    check_both_profiles();

    // MRS and unconditional-space encodings are not executed as MSR.
    instruction = 32'he10f_0000;
    #1ps;
    assert (tdmi_decode_match && arm946_decode_match);
    assert (!tdmi_execute_valid && !arm946_execute_valid);
    instruction = 32'hf121_f000;
    #1ps;
    assert (!tdmi_decode_match && !arm946_decode_match);
    assert (!tdmi_encoding_valid && !arm946_encoding_valid);
    assert (!tdmi_execute_valid && !arm946_execute_valid);

    assert (cases_checked == 991_233);
    $display("PASS profile-specific ARM MSR execution (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
